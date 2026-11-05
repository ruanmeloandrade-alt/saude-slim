const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const {patchOfflineQueue} = require('./patch-offline-queue.cjs');
const source = fs.readFileSync(process.env.BAILEYS_QUEUE_FIXTURE, 'utf8');
const settle = () => new Promise(resolve => setImmediate(resolve));
function queue(source, handler, errors, ws={isOpen:true}, ack=async()=>{}) {
  const start=source.indexOf('    const makeOfflineNodeProcessor = () => {');
  const end=source.indexOf('    const offlineNodeProcessor = makeOfflineNodeProcessor();',start);
  assert(start>=0&&end>start);
  return new Function('handleMessage','handleCall','handleReceipt','handleNotification','onUnexpectedError','ws','sendMessageAck','NACK_REASONS',source.slice(start,end)+'return makeOfflineNodeProcessor();')(
    handler,handler,handler,handler,(error)=>errors.push(error.message),ws,ack,{UnrecognizedStanzaType:490});
}
test('upstream queue reproduces the production freeze after a malformed pending message',async()=>{
  const done=[],errors=[];const q=queue(source,async n=>{if(n==='bad')throw Error('Unknown message type');done.push(n);},errors);
  q.enqueue('message','bad');q.enqueue('message','lead');await settle();
  assert.deepEqual(done,[]);assert.deepEqual(errors,['Unknown message type']);
});
test('one failed message leaves following inbound, receipt and notification nodes processing',async()=>{
  const done=[],errors=[];const q=queue(patchOfflineQueue(source),async n=>{if(n==='bad')throw Error('Unknown message type');done.push(n);},errors);
  q.enqueue('message','bad');q.enqueue('message','lead');q.enqueue('receipt','receipt');q.enqueue('notification','notification');await settle();q.enqueue('message','later');await settle();
  assert.deepEqual(done,['lead','receipt','notification','later']);assert.deepEqual(errors,['Unknown message type']);
});
test('subsequent failures do not duplicate successful nodes or freeze future arrivals',async()=>{
  const done=[],errors=[];const q=queue(patchOfflineQueue(source),async n=>{if(n.startsWith('bad'))throw Error(n);done.push(n);},errors);
  for(const n of ['bad1','a','bad2','b'])q.enqueue('message',n);await settle();q.enqueue('message','c');await settle();
  assert.deepEqual(done,['a','b','c']);assert.equal(errors.length,2);
});
test('patch is idempotent and refuses changed runtime code',()=>{
  assert.equal(patchOfflineQueue(patchOfflineQueue(source)),patchOfflineQueue(source));
  assert.throws(()=>patchOfflineQueue('changed upstream'),/refusing/);
});
test('unsupported Meta system node is NACKed so the next offline batch can arrive',async()=>{
 const done=[],errors=[],acks=[];let q;
 q=queue(patchOfflineQueue(source),async n=>{if(n.attrs.from.endsWith('@bot'))throw Error('Unknown message type');done.push(n.attrs.id);},errors,{isOpen:true},async(n,code)=>{acks.push({id:n.attrs.id,code});q.enqueue('message',{attrs:{id:'lead-after-batch',from:'5511999999999@s.whatsapp.net'}});});
 q.enqueue('message',{attrs:{id:'unsupported-system',from:'123@bot'}});await settle();
 assert.deepEqual(acks,[{id:'unsupported-system',code:490}]);assert.deepEqual(done,['lead-after-batch']);
});
test('failed direct lead and group messages are never ACKed by the fallback',async()=>{
 const errors=[],acks=[];const q=queue(patchOfflineQueue(source),async()=>{throw Error('Unknown message type');},errors,{isOpen:true},async n=>acks.push(n));
 for(const from of ['5511999999999@s.whatsapp.net','123@lid','123@g.us'])q.enqueue('message',{attrs:{from}});await settle();
 assert.equal(acks.length,0);assert.equal(errors.length,3);
});
test('a failed system ACK does not freeze subsequent messages',async()=>{
 const done=[],errors=[];const q=queue(patchOfflineQueue(source),async n=>{if(n.attrs.from.endsWith('@bot'))throw Error('Unknown message type');done.push(n.attrs.id);},errors,{isOpen:true},async()=>{throw Error('ACK unavailable');});
 q.enqueue('message',{attrs:{from:'123@bot'}});q.enqueue('message',{attrs:{id:'lead',from:'5511999999999@s.whatsapp.net'}});await settle();
 assert.deepEqual(done,['lead']);assert.deepEqual(errors,['Unknown message type','ACK unavailable']);
});
