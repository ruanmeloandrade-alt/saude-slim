import assert from 'node:assert/strict';
import { audienceTags, audienceMatches, querySlimAudience, readAudienceRows, audienceMessage, contactBlocked } from '../src/lib/slim-audience.core.ts';
let count=0;async function test(name,fn){await fn();count++;console.log('PASS '+name);}
const lead={id:'a',name:'Ana $&',email:null,phone:'5511999999999',status:'active',tags:['VIP',{name:'Cliente'}],created_at:'2026-10-01T23:45:00Z',updated_at:'2026-10-01T23:45:00Z',custom_data:{},last_message_from:null};
await test('JSON tags, objects and case-insensitive any/all/none',()=>{assert.deepEqual(audienceTags(lead.tags),['vip','cliente']);assert(audienceMatches(lead,{tagsAny:['vip'],tagsAll:['VIP','CLIENTE']}));assert(!audienceMatches(lead,{tagsNone:['cliente']}));});
await test('false filters and no prior message work',()=>{assert(audienceMatches(lead,{hasEmail:false,lastMessageFrom:'none'}));assert(!audienceMatches(lead,{hasPhone:false}));});
await test('end date includes entire selected day',()=>assert(audienceMatches(lead,{createdTo:'2026-10-01'})));
await test('merged leads are excluded even for any status',()=>assert(!audienceMatches({...lead,merged_into_id:'b'},{status:'any'})));
await test('custom-field comparators',()=>{const refs={fields:new Map([['a',new Map([['f','Aprovado']])]])};assert(audienceMatches(lead,{customFields:[{fieldId:'f',op:'contains',value:'prov'}]},refs));assert(!audienceMatches(lead,{customFields:[{fieldId:'f',op:'empty'}]},refs));});
await test('task state and products combine',()=>assert(audienceMatches(lead,{hasProducts:true,taskState:'has_open'},{products:new Set(['a']),tasks:new Map([['a',[{status:'pendente'}]]])})));
function fake(tables,fail) {const calls=[];return {calls,from(table){return {select(){return this;},eq(k,v){calls.push([table,k,v]);return this;},order(){return this;},async range(a,b){if(fail===table)return {data:null,error:{code:'42501'}};return {data:(tables[table]??[]).slice(a,Math.min(a+73,b+1)),error:null};}};}};}
await test('pagination over 1000 rows applies limit AFTER filtering',async()=>{const rows=Array.from({length:1205},(_,i)=>({...lead,id:String(i),tags:i>=1199?['match']:[]}));const db=fake({leads:rows});const r=await querySlimAudience(db,'workspace',{tagsAny:['match']},2);assert.equal(r.length,2);assert(db.calls.every(c=>c[1]==='workspace_id'&&c[2]==='workspace'));});
await test('preview count is not silently capped',async()=>assert.equal((await querySlimAudience(fake({leads:Array.from({length:2101},(_,i)=>({...lead,id:String(i)}))}),'ws',{})).length,2101));
await test('related table failure blocks calculation instead of false no-tasks',async()=>await assert.rejects(querySlimAudience(fake({leads:[lead]},'tasks'),'ws',{taskState:'none'})));
await test('workspace required',async()=>await assert.rejects(readAudienceRows(fake({}),'','leads','id')));
await test('malformed dates rejected',async()=>await assert.rejects(querySlimAudience(fake({}),'ws',{createdTo:'not-a-date'})));
await test('replacement tokens cannot interpret dollars from a contact name',()=>assert.equal(audienceMessage('Oi {{nome}}',lead),'Oi Ana $&'));
await test('opt-out and removed contact fences',()=>{assert(contactBlocked({...lead,custom_data:{opt_out:true}}));assert(contactBlocked({...lead,status:'archived'}));assert(!contactBlocked(lead));});
console.log(`${count}/${count} audience checks passed`);
