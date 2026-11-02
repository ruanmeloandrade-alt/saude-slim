import assert from 'node:assert/strict';
import fs from 'node:fs';
import ts from 'typescript';
import {PGlite} from '@electric-sql/pglite';
import * as tz from 'date-fns-tz';

const read=p=>fs.readFileSync(new URL('../'+p,import.meta.url),'utf8').replaceAll('\r\n','\n');
const compile=s=>ts.transpileModule(s,{compilerOptions:{target:ts.ScriptTarget.ES2022,module:ts.ModuleKind.CommonJS}}).outputText;
function load(path,deps={}){
 const m={exports:{}};
 Function('require','module','exports',compile(read(path)))(name=>{assert(name in deps,name);return deps[name]},m,m.exports);
 return m.exports;
}
const state=load('src/lib/pipeline-automation-state.ts');
const crm=load('src/lib/crm-mock.ts');
const core=load('src/lib/stage-execution.core.ts',{'date-fns-tz':tz,'./crm-mock':crm});
const source=read('src/legacy/crm.funis-de-venda.legacy.tsx');
const ast=ts.createSourceFile('front.tsx',source,ts.ScriptTarget.Latest,true,ts.ScriptKind.TSX);
const names=['enterAutomatize','saveAutomatize','assertAutomationPersistence'];
const declarations={};let loadEffect;
function visit(n){
 if(ts.isFunctionDeclaration(n)&&names.includes(n.name?.text))declarations[n.name.text]=n.getText(ast);
 if(ts.isCallExpression(n)&&n.expression.getText(ast)==='useEffect'&&n.arguments[0]?.getText(ast).includes('let cancelled = false;')&&n.arguments[0].getText(ast).includes('listStageAutomationsServer'))loadEffect=n.arguments[0].getText(ast);
 n.forEachChild(visit);
}
visit(ast);assert.equal(Object.keys(declarations).length,3);assert(loadEffect);
function callbacks(ctx){
 return Function(...Object.keys(ctx),compile(Object.values(declarations).join('\n')+'\nconst loadEffect='+loadEffect+';')+'\nreturn {enterAutomatize,saveAutomatize,assertAutomationPersistence,loadEffect};')(...Object.values(ctx));
}

const id=n=>`00000000-0000-4000-8000-${String(n).padStart(12,'0')}`;
const ws=id(1),otherWs=id(2),pipelines=[11,12,13,14].map(id),stages=[21,22,23,24].map(id);
const pg=new PGlite();
await pg.exec(`create schema private;
 create table public.workspaces(id uuid primary key);
 create table public.pipelines(id uuid primary key,workspace_id uuid references workspaces(id));
 create table public.pipeline_stages(id uuid primary key,pipeline_id uuid references pipelines(id),workspace_id uuid references workspaces(id));
 create function private.slim_workspace_access(w uuid,permission text) returns boolean language sql as $$ select w=current_setting('qa.workspace')::uuid $$;
`);
const migration=read('supabase/migrations/20261015115919_slim_restore_audiences_fields_stage_automations.sql');
await pg.exec(migration.split('\n').find(l=>l.startsWith('CREATE TABLE public.crm_stage_automations ')));
await pg.exec(migration.match(/CREATE FUNCTION public\.replace_crm_stage_automations[\s\S]+?END;\$f\$;/)[0]);
await pg.query("select set_config('qa.workspace',$1,false)",[ws]);
await pg.query('insert into workspaces values($1),($2)',[ws,otherWs]);
for(let n=0;n<4;n++){
 await pg.query('insert into pipelines values($1,$2)',[pipelines[n],ws]);
 await pg.query('insert into pipeline_stages values($1,$2,$3)',[stages[n],pipelines[n],ws]);
}
function action(n){return{id:'action-'+n,triggerId:'salesbot',title:'SalesBot',enabled:true,config:{kind:'salesbot',botId:'bot-'+n},execution:{trigger:{kind:'created-or-moved'},applyToExisting:false}}}
async function readSaved(pipelineId){
 const {rows}=await pg.query('select stage_id,action from crm_stage_automations where pipeline_id=$1 order by position',[pipelineId]);
 const automations={};for(const r of rows)(automations[r.stage_id]??=[]).push(r.action);
 return{automations};
}
async function saveReal({data}){
 const persisted=Object.fromEntries(Object.entries(data.automations).map(([s,list])=>[s,list.map(a=>({...a,execution:{...a.execution,applyToExisting:false},applyToExisting:false}))]));
 const {rows}=await pg.query('select replace_crm_stage_automations($1,$2::jsonb) n',[data.pipelineId,JSON.stringify(persisted)]);
 return{ok:true,count:rows[0].n,backfilled:0};
}
for(let n=0;n<4;n++)await saveReal({data:{pipelineId:pipelines[n],automations:{[stages[n]]:[action(n)]}}});

const store=new Map();const storage={getItem:k=>store.get(k)??null,setItem:(k,v)=>store.set(k,v),removeItem:k=>store.delete(k)};
const shared={saved:{},drafts:{},mode:'view',activeFunnelRef:{current:pipelines[0]},automationSaveRequest:{current:{}},automationReadEpoch:{current:{}},messages:[],calls:[]};
const draftKey=id=>'draft.'+id,savedKey=id=>'saved.'+id;
function context(n,overrides={}){
 const pipelineId=pipelines[n];
 return{
  ...state,...shared,stageActionStamp:core.stageActionStamp,
  funnelId:pipelineId,funnel:{id:pipelineId,stages:[{id:stages[n]}]},automations:{},draft:shared.drafts[pipelineId]??null,openingAutomations:false,savingAutomations:false,
  localStorage:storage,sessionStorage:storage,stageAutomationDraftStorageKey:draftKey,stageAutomationStorageKey:savedKey,
  setAutomations:next=>{shared.saved=state.updatePipelineAutomationState(shared.saved,pipelineId,next,{})},
  setDraft:next=>{shared.drafts=state.updatePipelineAutomationState(shared.drafts,pipelineId,next,null)},
  setMode:mode=>{shared.mode=mode},setOpeningAutomations(){},setSavingAutomations(){},setConfiguring(){},setColorMode(){},setSelectedColorStageId(){},
  toast:Object.fromEntries(['error','success','info'].map(kind=>[kind,message=>shared.messages.push({kind,message})])),
  listStageAutomationsServer:({data})=>readSaved(data.pipelineId),
  saveStageAutomationsServer:input=>{shared.calls.push(input);return saveReal(input)},
  ...overrides,
 };
}
function deferred(){let resolve,reject;const promise=new Promise((a,b)=>{resolve=a;reject=b});return{promise,resolve,reject}}
async function flush(){await new Promise(resolve=>setImmediate(resolve))}
let passed=0;
async function test(name,fn){store.clear();shared.messages=[];shared.calls=[];shared.mode='view';await fn();passed++;console.log('PASS',name)}

await test('fast opening waits for the actual saved pipeline instead of cloning an empty view',async()=>{
 const pending=deferred();shared.activeFunnelRef.current=pipelines[1];
 const cb=callbacks(context(1,{listStageAutomationsServer:()=>pending.promise}));
 const opening=cb.enterAutomatize();assert.equal(shared.mode,'view');
 pending.resolve(await readSaved(pipelines[1]));await opening;
 assert.equal(shared.mode,'automatize');assert.equal(shared.drafts[pipelines[1]][stages[1]][0].config.botId,'bot-1');
});
await test('late opening response cannot open another pipeline or replace its draft',async()=>{
 const pending=deferred();shared.activeFunnelRef.current=pipelines[0];
 const cb=callbacks(context(0,{listStageAutomationsServer:()=>pending.promise}));
 const opening=cb.enterAutomatize();shared.activeFunnelRef.current=pipelines[2];
 const original={[stages[2]]:[{...action(2),title:'Unsaved reactivation'}]};shared.drafts[pipelines[2]]=original;
 pending.resolve(await readSaved(pipelines[0]));await opening;
 assert.equal(shared.mode,'view');assert.strictEqual(shared.drafts[pipelines[2]],original);
});
await test('all four pipelines retain their separate drafts and real PostgreSQL settings',async()=>{
 for(let n=0;n<4;n++){
  shared.activeFunnelRef.current=pipelines[n];
  const draft={[stages[n]]:[{...action(n),title:'Draft '+n}]};storage.setItem(draftKey(pipelines[n]),JSON.stringify(draft));
  await callbacks(context(n)).enterAutomatize();
 }
 for(let n=0;n<4;n++)assert.equal(shared.drafts[pipelines[n]][stages[n]][0].title,'Draft '+n);
 assert.equal(Object.keys(shared.drafts[pipelines[0]])[0],stages[0]);
});
await test('foreign old browser drafts are preserved in recovery before showing the correct saved bots',async()=>{
 shared.activeFunnelRef.current=pipelines[1];const raw=JSON.stringify({[stages[0]]:[action(0)]});storage.setItem(draftKey(pipelines[1]),raw);
 await callbacks(context(1)).enterAutomatize();
 assert.equal(shared.drafts[pipelines[1]][stages[1]][0].config.botId,'bot-1');
 assert([...store].some(([key,value])=>key.startsWith(draftKey(pipelines[1])+':recovery:')&&value===raw));
});
await test('failed loading never opens an empty editor or overwrites the backup',async()=>{
 shared.activeFunnelRef.current=pipelines[2];storage.setItem(draftKey(pipelines[2]),'preserve-me');
 await callbacks(context(2,{listStageAutomationsServer:async()=>{throw Error('Temporary read failure')}})).enterAutomatize();
 assert.equal(shared.mode,'view');assert.equal(storage.getItem(draftKey(pipelines[2])),'preserve-me');
 assert(shared.messages.some(m=>m.kind==='error'));
});
await test('late background read cannot overwrite a newly loaded and confirmed save',async()=>{
 shared.activeFunnelRef.current=pipelines[0];const pending=deferred();
 callbacks(context(0,{listStageAutomationsServer:()=>pending.promise})).loadEffect();
 await callbacks(context(0)).enterAutomatize();
 const changed={[stages[0]]:[{...action(0),title:'Confirmed latest'}]};
 await callbacks(context(0)).saveAutomatize(changed,true);
 pending.resolve({automations:{[stages[0]]:[action(0)]}});await flush();
 assert.equal(shared.saved[pipelines[0]][stages[0]][0].title,'Confirmed latest');
});
await test('saving a previous pipeline cannot close or clear the newly selected editor',async()=>{
 shared.activeFunnelRef.current=pipelines[0];const pending=deferred();
 const input={[stages[0]]:[{...action(0),title:'Saved A'}]};
 const cb=callbacks(context(0,{saveStageAutomationsServer:async value=>{const result=await saveReal(value);await pending.promise;return result}}));
 const saving=cb.saveAutomatize(input);await flush();
 shared.activeFunnelRef.current=pipelines[3];shared.mode='automatize';const other={[stages[3]]:[{...action(3),title:'Still editing B'}]};shared.drafts[pipelines[3]]=other;
 pending.resolve();await saving;
 assert.equal(shared.mode,'automatize');assert.strictEqual(shared.drafts[pipelines[3]],other);
 assert.equal(shared.saved[pipelines[0]][stages[0]][0].title,'Saved A');
});
await test('foreign stages are rejected before a write and cannot erase any saved settings',async()=>{
 shared.activeFunnelRef.current=pipelines[1];const before=await readSaved(pipelines[1]);
 await callbacks(context(1)).saveAutomatize({[stages[0]]:[action(0)]});
 assert.equal(shared.calls.length,0);assert.deepEqual(await readSaved(pipelines[1]),before);
 assert.throws(()=>state.scopePipelineAutomations({[stages[1]]:[{...action(1),stageIds:[stages[3]]}]},[stages[1]]),/outro funil/);
});
await test('same action count with a different selected bot must not report success',async()=>{
 shared.activeFunnelRef.current=pipelines[2];const input={[stages[2]]:[action(2)]};
 const cb=callbacks(context(2,{listStageAutomationsServer:async()=>({automations:{[stages[2]]:[{...action(2),config:{kind:'salesbot',botId:'WRONG'}}]}})}));
 await assert.rejects(()=>cb.saveAutomatize(input,true),/configuração/);
 assert(storage.getItem(draftKey(pipelines[2])));assert(shared.drafts[pipelines[2]]);
 assert(!shared.messages.some(m=>m.kind==='success'));
});
await test('request IDs are scoped by pipeline and retained for a failed retry',async()=>{
 const failure=async()=>{throw Error('QA unavailable')};
 for(const n of [0,1]){
  shared.activeFunnelRef.current=pipelines[n];await assert.rejects(()=>callbacks(context(n,{saveStageAutomationsServer:failure})).saveAutomatize({[stages[n]]:[action(n)]},true));
 }
 const first=shared.automationSaveRequest.current[pipelines[0]],second=shared.automationSaveRequest.current[pipelines[1]];
 assert(first&&second&&first!==second);
 shared.activeFunnelRef.current=pipelines[0];await assert.rejects(()=>callbacks(context(0,{saveStageAutomationsServer:failure})).saveAutomatize({[stages[0]]:[action(0)]},true));
 assert.equal(shared.automationSaveRequest.current[pipelines[0]],first);
});
await test('real atomic RPC round trips each pipeline without changing the other three',async()=>{
 for(let n=0;n<4;n++){
  const others=await Promise.all(pipelines.map(readSaved));
  await saveReal({data:{pipelineId:pipelines[n],automations:{[stages[n]]:[{...action(n),title:'Final '+n}]}}});
  assert.equal((await readSaved(pipelines[n])).automations[stages[n]][0].title,'Final '+n);
  for(let j=0;j<4;j++)if(j!==n)assert.deepEqual(await readSaved(pipelines[j]),others[j]);
 }
 const before=await readSaved(pipelines[0]);
 await assert.rejects(()=>saveReal({data:{pipelineId:pipelines[0],automations:{[stages[1]]:[action(1)]}}}),/inválida/);
 assert.deepEqual(await readSaved(pipelines[0]),before);
});
await pg.close();console.log(`${passed}/${passed} checks; actual UI callbacks and real atomic RPC in isolated PostgreSQL. No customer mutations or external messages.`);
