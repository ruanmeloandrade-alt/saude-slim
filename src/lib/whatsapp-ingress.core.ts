import { slimSanitizeEvolutionMessage } from './slim-inbound-media.core';
import {whatsappIdentityFromEvolutionJids} from './whatsapp-identity';

export const QUEUED_EVOLUTION_EVENTS = new Set(['messages.upsert','send.message','messages.update']);
export const INGRESS_MAX_BYTES = 24 * 1024 * 1024;
type Obj = Record<string, any>;
export type IngressItem = {event: string; payload: Obj; conversation: string; messageId: string|null; identity: string; reviewReason: string|null};
const object=(x:unknown):Obj=>x&&typeof x==='object'&&!Array.isArray(x)?x as Obj:{};
export function normalizeEvolutionIngress(input:unknown, now=Date.now()):IngressItem[] {
 const envelope=object(input),event=String(envelope.event??envelope.type??'').toLowerCase().replaceAll('_','.');
 if(!QUEUED_EVOLUTION_EVENTS.has(event))return [];
 const data=envelope.data,root=object(data);
 const rows=Array.isArray(data)?data:Array.isArray(root.messages)?root.messages:[root];
 if(!rows.length||rows.length>100)throw new Error('Quantidade de eventos fora do limite.');
 return rows.map(value=>{
  const item=object(value),key=object(item.key);
  const id=typeof key.id==='string'?key.id:typeof item.keyId==='string'?item.keyId:null;
  const jid=String(key.remoteJid??item.remoteJid??'');
  let reviewReason:string|null=null;
  if(!id||id.length>250||!jid||jid.length>200)reviewReason='Identidade do evento incompleta.';
  let normalized=item;
  if(event==='messages.update'){
   const raw=String(item.status??object(item.update).status??'').toLowerCase();
   const status:Record<string,string>={server_ack:'sent',delivery_ack:'delivered','2':'sent','3':'delivered','4':'read','5':'played',read:'read',played:'played',sent:'sent',delivered:'delivered',error:'error'};
   if(!status[raw])reviewReason='Estado de entrega desconhecido.';
   normalized={...item,key:{...key,id,remoteJid:jid},status:status[raw]??raw};
  }else{
   const timestamp=Number(item.messageTimestamp);
   if(!Number.isFinite(timestamp)||timestamp<1262304000||timestamp*1000>now+300000)reviewReason='Data da mensagem invalida.';
   if(key.fromMe!==true&&key.fromMe!==false)reviewReason='Direcao da mensagem ausente.';
  }
  const clean=slimSanitizeEvolutionMessage({...envelope,event,data:normalized}) as Obj;
  const identity=JSON.stringify([event==='send.message'?'messages.upsert':event,id,event==='messages.update'?null:key.fromMe??item.fromMe,event==='messages.update'?normalized.status:null,reviewReason?clean.data:null]);
  const resolved=whatsappIdentityFromEvolutionJids(jid,key.remoteJidAlt);
  return {event,payload:clean,conversation:resolved?.remoteJid??jid??'unresolved',messageId:id,identity,reviewReason};
 });
}

export async function boundedWebhookJson(request:Request):Promise<unknown>{
 const length=Number(request.headers.get('content-length'));
 if(Number.isFinite(length)&&length>INGRESS_MAX_BYTES)throw new Error('Payload acima do limite.');
 if(!request.body)throw new Error('Payload vazio.');
 const reader=request.body.getReader();const chunks:Uint8Array[]=[];let size=0;
 try{for(;;){const part=await reader.read();if(part.done)break;size+=part.value.byteLength;if(size>INGRESS_MAX_BYTES)throw new Error('Payload acima do limite.');chunks.push(part.value);}}
 catch(error){await reader.cancel().catch(()=>{});throw error;}
 const all=new Uint8Array(size);let offset=0;for(const chunk of chunks){all.set(chunk,offset);offset+=chunk.byteLength;}
 return JSON.parse(new TextDecoder().decode(all));
}
