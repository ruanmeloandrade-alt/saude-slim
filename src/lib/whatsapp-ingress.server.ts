import {createHash} from 'node:crypto';
import {supabaseAdmin} from '@/integrations/supabase/client.server';
import {boundedWebhookJson,normalizeEvolutionIngress,QUEUED_EVOLUTION_EVENTS} from './whatsapp-ingress.core';

type Input={request:Request;params:{secret:string}};
type Processor=(input:Input)=>Promise<Response>;
const db=supabaseAdmin as any;
const state=globalThis as typeof globalThis&{__slimIngress?:{busy:boolean;active:number;timer?:ReturnType<typeof setInterval>;processor?:Processor}};
const worker=state.__slimIngress??={busy:false,active:0};
async function deadline<T>(operation:PromiseLike<T>):Promise<T>{
 let timer:ReturnType<typeof setTimeout>|undefined;
 try{return await Promise.race([Promise.resolve(operation),new Promise<T>((_,reject)=>{timer=setTimeout(()=>reject(new Error('database deadline')),10000);})]);}
 finally{if(timer)clearTimeout(timer);}
}

export async function acceptEvolutionIngress(input:Input,processor:Processor):Promise<Response>{
 worker.processor=processor;
 const secret=input.params.secret;
 if(!secret||secret.length<20)return new Response('bad secret',{status:400});
 let payload:any;
 try{payload=await boundedWebhookJson(input.request);}catch{return Response.json({ok:false,error:'Payload invalido ou acima do limite.'},{status:400});}
 const event=String(payload?.event??payload?.type??'').toLowerCase().replaceAll('_','.');
 if(!QUEUED_EVOLUTION_EVENTS.has(event)){
  // Preserve the existing lifecycle handling for non-message events.
  return processor({params:input.params,request:new Request('http://internal/evolution',{method:'POST',headers:input.request.headers,body:JSON.stringify(payload)})});
 }
 const encryption=process.env.INTEGRATION_ENCRYPTION_KEY;
 if(!encryption)return new Response('server misconfigured',{status:503});
 let session:any;
 try{session=await deadline(db.rpc('get_evolution_session_by_secret',{_webhook_secret:secret,_key:encryption}));}
 catch{return new Response('session lookup unavailable',{status:503});}
 if(session.error)return new Response('session lookup unavailable',{status:503});
 if(!session.data)return new Response('unknown session',{status:404});
 const s=session.data;
 const apiKey=input.request.headers.get('apikey');
 if(apiKey&&apiKey!==s.api_key)return new Response('unauthorized',{status:401});
 if(s.session_id!=='af98d195-d129-43cc-b3c8-2afa7e1a105e')return processor({params:input.params,request:new Request('http://internal/evolution',{method:'POST',headers:input.request.headers,body:JSON.stringify(payload)})});
 if(payload.instance&&payload.instance!==s.instance_name)return new Response('obsolete instance',{status:409});
 let items;try{items=normalizeEvolutionIngress(payload);}catch{return Response.json({ok:false,error:'Lote invalido.'},{status:400});}
 const rows=items.map(item=>({workspace_id:s.workspace_id,session_id:s.session_id,event_key:createHash('sha256').update(item.identity).digest('hex'),
  event_type:item.event,conversation_key:item.conversation,provider_message_id:item.messageId,payload:item.payload,
  status:item.reviewReason?'review':'queued',last_error:item.reviewReason}));
 let saved:any;
 try{saved=await deadline(db.from('slim_whatsapp_ingress').upsert(rows,{onConflict:'workspace_id,session_id,event_key',ignoreDuplicates:true}).select('id'));}
 catch{return new Response('receipt unavailable',{status:503});}
 if(saved.error)return Response.json({ok:false,error:'Recebimento nao persistido.'},{status:503});
 ensureWhatsappIngressWorker();void tickWhatsappIngress().catch(report);
 return Response.json({ok:true,accepted:items.length,persisted:saved.data?.length??0},{status:202});
}

export function ensureWhatsappIngressWorker(){
 if(worker.timer)return;
 worker.timer=setInterval(()=>{void tickWhatsappIngress().catch(report);},1500);worker.timer.unref?.();
}
function report(){console.error('[WhatsApp ingress] Processamento indisponivel; eventos permanecem registrados.');}
export async function tickWhatsappIngress(){
 if(worker.busy||worker.active>=8)return;worker.busy=true;
 try{
  const result:any=await deadline(db.rpc('slim_claim_whatsapp_ingress',{_limit:Math.min(3,8-worker.active)}));
  if(result.error)throw new Error('claim unavailable');
  if(!result.data?.length)return;
  const processor=worker.processor??(await import('@/routes/api/public/evolution/webhook.$secret')).processEvolutionWebhook;
  for(const row of result.data??[]){
   worker.active++;
   void (async()=>{
   let status='done',reason:string|null=null;let timer:ReturnType<typeof setTimeout>|undefined;
   try{
    const session:any=await deadline(db.from('whatsapp_web_sessions').select('webhook_secret').eq('id',row.session_id).eq('workspace_id',row.workspace_id).single());
    if(session.error||!session.data?.webhook_secret)throw new Error('session unavailable');
    const response=await Promise.race([processor({params:{secret:session.data.webhook_secret},request:new Request('http://internal/evolution',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(row.payload)})}),
     new Promise<Response>((_,reject)=>{timer=setTimeout(()=>reject(new Error('deadline')),90000);})]);
    if(!response.ok){status='review';reason='Etapa de processamento falhou; revisar sem repetir envios.';}
    const item=row.payload?.data,key=item?.key??{};
    if(String(key.remoteJid??'').endsWith('@lid')&&!String(key.remoteJidAlt??'').endsWith('@s.whatsapp.net')){status='review';reason='Telefone nao resolvido; mensagem preservada para revisao.';}
   }catch{status='review';reason='Processamento interrompido ou incerto; revisar antes de retomar.';}
   finally{if(timer)clearTimeout(timer);}
   const finished:any=await deadline(db.rpc('slim_finish_whatsapp_ingress',{_id:row.id,_lease:row.lease_id,_status:status,_reason:reason}));
   if(finished.error||finished.data!==true)throw new Error('receipt not confirmed');
   })().catch(report).finally(()=>{worker.active--;});
  }
 }finally{worker.busy=false;}
}
