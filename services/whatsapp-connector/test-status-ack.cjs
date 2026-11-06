const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const {spawnSync} = require('node:child_process');
const {EventEmitter} = require('node:events');
const {patchOfflineQueue} = require('./patch-offline-queue.cjs');
const {patchStatusAck} = require('./patch-status-ack.cjs');
const source = fs.readFileSync(process.env.BAILEYS_QUEUE_FIXTURE, 'utf8').replace(/\r\n/g, '\n');
const patched = patchStatusAck(patchOfflineQueue(source));
const settle = () => new Promise(resolve => setImmediate(resolve));
const status = (offline, id='status-1') => ({tag:'status',attrs:{id,from:'status@broadcast',type:'media',...(offline?{offline:'true'}:{})}});

function runtime(code, ack=async()=>{}) {
    const ws = new EventEmitter(); ws.isOpen=true;
    const handled=[],errors=[],confirmed=[];
    const start=code.indexOf('    const processNodeWithBuffer = async');
    const end=code.indexOf("    ws.on('CB:notification'",start);
    assert(start>=0&&end>start);
    const handler=async n=>handled.push(n.attrs.id);
    new Function('ws','ev','handleMessage','handleCall','handleReceipt','handleNotification',
        'sendMessageAck','onUnexpectedError','NACK_REASONS','console',code.slice(start,end))(
        ws,{buffer(){},flush(){}},handler,handler,handler,handler,ack,
        (error)=>errors.push(error.message),{UnrecognizedStanzaType:490},
        {info:(message,detail)=>confirmed.push({message,detail})});
    return {ws,handled,errors,confirmed,async emit(event,node){const f=ws.listeners(event)[0];assert(f,'handler registered');await f(node);await settle();}};
}

test('upstream confirms the missing handler that leaves status stanzas unacknowledged',()=>{
    assert.equal(runtime(source).ws.listenerCount('CB:status'),0);
});
test('live media status gets exactly one positive ACK without invoking the lead handler',async()=>{
    const calls=[],r=runtime(patched,async(...args)=>calls.push(args)),node=status(false);
    await r.emit('CB:status',node);
    assert.deepEqual(calls,[[node]]);assert.deepEqual(r.handled,[]);assert.deepEqual(r.errors,[]);
    assert.equal(r.confirmed.length,1);assert.deepEqual(r.confirmed[0].detail,{offline:false});
});
test('offline status stays in FIFO order between real message, receipt and notification processing',async()=>{
    const order=[],r=runtime(patched,async n=>order.push('ack:'+n.attrs.id));
    const oldHandler=r.ws.listeners('CB:message')[0];
    // An offline message ahead of status is processed by the unchanged message handler.
    await oldHandler({tag:'message',attrs:{offline:'true',id:'lead-before'}});
    await r.emit('CB:status',status(true));
    await r.emit('CB:receipt',{tag:'receipt',attrs:{offline:'true',id:'receipt-after'}});
    await r.emit('CB:message',{tag:'message',attrs:{offline:'true',id:'lead-after'}});
    assert.deepEqual(r.handled,['lead-before','receipt-after','lead-after']);
    assert.deepEqual(order,['ack:status-1']);assert.deepEqual(r.errors,[]);
    assert.deepEqual(r.confirmed[0].detail,{offline:true});
});
test('a pending status ACK blocks later offline messages until it resolves, preserving queue order',async()=>{
    let release;const pending=new Promise(resolve=>{release=resolve;});
    const r=runtime(patched,async()=>pending);
    await r.emit('CB:status',status(true));
    await r.emit('CB:message',{tag:'message',attrs:{offline:'true',id:'later'}});
    assert.deepEqual(r.handled,[]);release();await settle();assert.deepEqual(r.handled,['later']);
});
test('failed offline status ACK does not freeze later inbound messages or falsely log success',async()=>{
    const r=runtime(patched,async()=>{throw Error('transport unavailable');});
    await r.emit('CB:status',status(true));
    await r.emit('CB:message',{tag:'message',attrs:{offline:'true',id:'lead'}});
    assert.deepEqual(r.handled,['lead']);assert.deepEqual(r.errors,['transport unavailable']);assert.equal(r.confirmed.length,0);
});
test('failed live status ACK is isolated and the next live status can succeed',async()=>{
    let count=0;const r=runtime(patched,async()=>{if(++count===1)throw Error('temporary');});
    await r.emit('CB:status',status(false,'a'));await r.emit('CB:status',status(false,'b'));
    assert.deepEqual(r.errors,['temporary']);assert.equal(r.confirmed.length,1);
});
test('actual upstream sendMessageAck preserves status routing/type and omits any error code',async()=>{
    const start=source.indexOf('    const sendMessageAck = async');
    const end=source.indexOf('    const rejectCall = async',start);
    assert(start>=0&&end>start);const sent=[];
    const ack=new Function('sendNode','logger','authState','getBinaryNodeChild',
        source.slice(start,end)+'return sendMessageAck;')(
        async n=>sent.push(n),{debug(){}},{},()=>{throw Error('message branch must not run');});
    const node=status(false);node.attrs.participant='participant';node.attrs.recipient='recipient';
    const r=runtime(patched,ack);await r.emit('CB:status',node);
    assert.deepEqual(sent,[{tag:'ack',attrs:{id:'status-1',to:'status@broadcast',class:'status',type:'media',participant:'participant',recipient:'recipient'}}]);
});
test('combined patch remains idempotent and has a single status listener and queue entry',()=>{
    assert.equal(patchStatusAck(patched),patched);assert.equal(patchOfflineQueue(patched),patched);
    assert.equal(patched.split("ws.on('CB:status'").length-1,1);
    assert.equal(patched.split("['status', handleStatus]").length-1,1);
    assert.throws(()=>patchStatusAck('upstream changed'),/refusing/);
    assert.throws(()=>patchStatusAck(patched.replace("['status', handleStatus]", "['other', handleStatus]")),/incomplete/);
    assert.throws(()=>patchStatusAck(source.replace("ws.on('CB:message'", "ws.on('CB:status'")),/already handles/);
});
test('complete patched ESM runtime parses before deployment',()=>{
    const r=spawnSync(process.execPath,['--input-type=module','--check'],{input:patched,encoding:'utf8'});
    assert.equal(r.status,0,r.stderr);
});
