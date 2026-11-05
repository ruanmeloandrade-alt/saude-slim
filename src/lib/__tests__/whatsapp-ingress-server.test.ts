import{beforeEach,afterEach,it,expect,vi}from'vitest';
const {db}=vi.hoisted(()=>({db:{rpc:vi.fn(),from:vi.fn()}}));
vi.mock('@/integrations/supabase/client.server',()=>({supabaseAdmin:db}));
const session={session_id:'af98d195-d129-43cc-b3c8-2afa7e1a105e',workspace_id:'c49945db-1960-461a-9339-a43b8403bdd9',instance_name:'commercial-fixture',api_key:'test-key'};
const payload={event:'MESSAGES_UPSERT',instance:'commercial-fixture',data:{key:{id:'provider-id',remoteJid:'5511999999999@s.whatsapp.net',fromMe:false},messageTimestamp:1700000000,message:{conversation:'test fixture'}}};
let saved:any[]=[];let persistError:any=null;let claims:any[]=[];let module:typeof import('../whatsapp-ingress.server');
beforeEach(async()=>{
 vi.resetModules();vi.clearAllMocks();vi.stubEnv('INTEGRATION_ENCRYPTION_KEY','isolated-test-key');saved=[];persistError=null;claims=[];
 db.rpc.mockImplementation(async(name:string)=>name==='get_evolution_session_by_secret'?{data:session,error:null}:name==='slim_claim_whatsapp_ingress'?{data:claims.splice(0,3),error:null}:{data:true,error:null});
 db.from.mockImplementation((table:string)=>{
  if(table==='slim_whatsapp_ingress')return{upsert:(rows:any[],options:any)=>{expect(options.ignoreDuplicates).toBe(true);saved=rows;return{select:async()=>({data:rows.map((_,i)=>({id:String(i)})),error:persistError})};}};
  const q:any={select:()=>q,eq:()=>q,single:async()=>({data:{webhook_secret:'synthetic-session-secret'},error:null})};return q;
 });
 module=await import('../whatsapp-ingress.server');
});
afterEach(()=>{const state=(globalThis as any).__slimIngress;if(state?.timer)clearInterval(state.timer);delete(globalThis as any).__slimIngress;vi.unstubAllEnvs();});
const input=(body:any=payload)=>({params:{secret:'synthetic-session-secret'},request:new Request('http://internal',{method:'POST',body:JSON.stringify(body)})});
it('acknowledges only after persistence without executing the bot inline',async()=>{
 const processor=vi.fn(async()=>Response.json({ok:true}));
 const response=await module.acceptEvolutionIngress(input(),processor);
 expect(response.status).toBe(202);expect(saved).toHaveLength(1);expect(saved[0].status).toBe('queued');expect(processor).not.toHaveBeenCalled();
});
it('returns 503 when persistence fails, allowing the provider to retry',async()=>{
 persistError={message:'controlled failure'};const processor=vi.fn();
 expect((await module.acceptEvolutionIngress(input(),processor)).status).toBe(503);expect(processor).not.toHaveBeenCalled();
});
it('rejects obsolete physical instances and invalid header credentials',async()=>{
 const processor=vi.fn();expect((await module.acceptEvolutionIngress(input({...payload,instance:'deleted-instance'}),processor)).status).toBe(409);
 const request=input();request.request.headers.set('apikey','wrong');expect((await module.acceptEvolutionIngress(request,processor)).status).toBe(401);expect(saved).toHaveLength(0);
});
it('preserves malformed rows for review',async()=>{
 await module.acceptEvolutionIngress(input({...payload,data:{message:{conversation:'malformed'}}}),vi.fn());
 expect(saved[0].status).toBe('review');expect(saved[0].payload.data.message.conversation).toBe('malformed');
});
it('records a processing failure for review without automatically repeating it',async()=>{
 const processor=vi.fn(async()=>new Response('controlled error',{status:500}));
 await module.acceptEvolutionIngress(input(),processor);
 await vi.waitFor(()=>expect((globalThis as any).__slimIngress.busy).toBe(false));
 claims=[{id:'row',session_id:session.session_id,workspace_id:session.workspace_id,lease_id:'lease',payload}];
 await module.tickWhatsappIngress();
 await vi.waitFor(()=>expect(db.rpc).toHaveBeenCalledWith('slim_finish_whatsapp_ingress',expect.objectContaining({_id:'row',_lease:'lease',_status:'review'})));
 await module.tickWhatsappIngress();expect(processor).toHaveBeenCalledTimes(1);
});
