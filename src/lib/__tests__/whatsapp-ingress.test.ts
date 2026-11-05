import {describe,it,expect} from 'vitest';
import {boundedWebhookJson,INGRESS_MAX_BYTES,normalizeEvolutionIngress} from '../whatsapp-ingress.core';
import {routeInboundAgentOwnership} from '../slim-inbound-owner.core';
const message=(id='A')=>({key:{id,remoteJid:'5511999999999@s.whatsapp.net',fromMe:false},messageTimestamp:1700000000,message:{conversation:'ola'}});
describe('durable commercial ingress',()=>{
 it('splits mixed batches and isolates malformed items',()=>{
  const rows=normalizeEvolutionIngress({event:'MESSAGES_UPSERT',data:[message(),{message:{conversation:'invalida'}}]});
  expect(rows).toHaveLength(2);expect(rows[0].reviewReason).toBeNull();expect(rows[1].reviewReason).toBeTruthy();
 });
 it('deduplicates upsert and send callbacks for the same provider identity',()=>{
  const m={...message(),key:{...message().key,fromMe:true}};
  expect(normalizeEvolutionIngress({event:'SEND_MESSAGE',data:m})[0].identity).toBe(normalizeEvolutionIngress({event:'MESSAGES_UPSERT',data:m})[0].identity);
 });
 it('keeps different malformed records instead of collapsing all missing identities',()=>{
  const rows=normalizeEvolutionIngress({event:'MESSAGES_UPSERT',data:[{message:{conversation:'a'}},{message:{conversation:'b'}}]});
  expect(rows[0].identity).not.toBe(rows[1].identity);
 });
 it('normalizes official flat delivery callbacks',()=>{
  const row=normalizeEvolutionIngress({event:'MESSAGES_UPDATE',data:{keyId:'A',remoteJid:'5511999999999@s.whatsapp.net',status:'DELIVERY_ACK'}})[0];
  expect(row.payload.data.key.id).toBe('A');expect(row.payload.data.status).toBe('delivered');expect(row.reviewReason).toBeNull();
 });
 it('quarantines unknown delivery state',()=>expect(normalizeEvolutionIngress({event:'messages.update',data:{keyId:'A',remoteJid:'a',status:'future'}})[0].reviewReason).toBeTruthy());
 it('serializes proven LID alternate with the same direct conversation',()=>{
  const row=normalizeEvolutionIngress({event:'messages.upsert',data:{...message(),key:{...message().key,remoteJid:'12345@lid',remoteJidAlt:message().key.remoteJid}}})[0];
  expect(row.conversation).toBe(message().key.remoteJid);
 });
 it('never converts an unresolved LID into a phone',()=>{
  const row=normalizeEvolutionIngress({event:'messages.upsert',data:{...message(),key:{...message().key,remoteJid:'12345@lid'}}})[0];
  expect(row.conversation).toBe('12345@lid');
 });
 it('strips credentials and embedded attachment bytes',()=>{
  const row=normalizeEvolutionIngress({event:'messages.upsert',apikey:'secret',data:{...message(),base64:'sensitive',message:{imageMessage:{jpegThumbnail:'binary',mediaKey:'needed-for-download'}}}})[0];
  expect(row.payload.apikey).toBeUndefined();expect(row.payload.data.base64).toBeUndefined();expect(row.payload.data.message.imageMessage.jpegThumbnail).toBeUndefined();expect(row.payload.data.message.imageMessage.mediaKey).toBe('needed-for-download');
 });
 it('accepts streamed JSON and rejects oversized bodies before parsing',async()=>{
  expect(await boundedWebhookJson(new Request('http://internal',{method:'POST',body:'{"a":1}'}))).toEqual({a:1});
  await expect(boundedWebhookJson(new Request('http://internal',{method:'POST',body:'{}',headers:{'content-length':String(INGRESS_MAX_BYTES+1)}}))).rejects.toThrow();
  await expect(boundedWebhookJson(new Request('http://internal',{method:'POST',body:'not json'}))).rejects.toThrow();
 });
 it('rejects unbounded batches and future timestamps',()=>{
  expect(()=>normalizeEvolutionIngress({event:'messages.upsert',data:Array(101).fill(message())})).toThrow();
  expect(normalizeEvolutionIngress({event:'messages.upsert',data:{...message(),messageTimestamp:Date.now()/1000+9999}})[0].reviewReason).toBeTruthy();
 });
 it('propagates a failed direct AI turn to review rather than reporting success',async()=>{
  const lead={phone:'+5511999999999',active_conversation_agent_id:'agent',active_conversation_agent_version:1,ai_paused:false};
  const db={from(){const q:any={select:()=>q,eq:()=>q,in:async()=>({data:[],error:null}),maybeSingle:async()=>({data:lead,error:null})};return q;}};
  await expect(routeInboundAgentOwnership(db,{workspaceId:'ws',leadId:'lead'},{resume:async()=>{},turn:async()=>({handoff:false,error:'provider failed'})})).rejects.toThrow('retida');
 });
});
