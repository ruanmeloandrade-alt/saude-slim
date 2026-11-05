const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const {patchOfflineQueue} = require('./patch-offline-queue.cjs');
const source = fs.readFileSync(process.env.BAILEYS_QUEUE_FIXTURE, 'utf8');
const settle = () => new Promise(resolve => setImmediate(resolve));
function queue(source, handler, errors, ws={isOpen:true}) {
  const start=source.indexOf('    const makeOfflineNodeProcessor = () => {');
  const end=source.indexOf('    const offlineNodeProcessor = makeOfflineNodeProcessor();',start);
  assert(start>=0&&end>start);
  return new Function('handleMessage','handleCall','handleReceipt','handleNotification','onUnexpectedError','ws',source.slice(start,end)+'return makeOfflineNodeProcessor();')(
    handler,handler,handler,handler,(error)=>errors.push(error.message),ws);
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
