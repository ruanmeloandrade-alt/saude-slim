import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
const graph=JSON.parse(readFileSync(new URL('./fixtures/slim-tracking-contains.json',import.meta.url),'utf8'));
const start=graph.find(b=>b.config.isStartBlock);
assert.equal(graph.length,28);
assert.equal(start.config.roleta.length,13);
assert.ok(start.config.roleta.every(r=>r.tipo==='contem'&&r.alvo==='mensagem'&&r.label===r.valor));
assert.equal(new Set(start.config.roleta.map(r=>r.nextBlockId)).size,13);
function trace(text){
 const rule=start.config.roleta.find(r=>text.toLowerCase().includes(r.valor.toLowerCase()));
 const action=graph.find(b=>b.id===(rule?.nextBlockId??start.next_block_id));
 const bot=action.type==='acao'?graph.find(b=>b.id===action.next_block_id):action;
 assert.equal(bot.type,'iniciar-salesbot');
 assert.equal(bot.config.destinoBotId,'f2b2925f-cdae-9488-4b86-f64191b26bb8');
 return {rule,action,bot};
}
let count=0;const destinations=new Set();
for(const r of start.config.roleta){
 for(const message of [r.valor, 'Olá, vi o anúncio '+r.valor+' e quero saber mais', r.valor.toLowerCase()]){
  const result=trace(message);assert.equal(result.rule.valor,r.valor);
  assert.equal(result.action.config.acaoTipo,'tags');
  assert.equal(result.action.config.acaoConfig,'🎯META ADS,'+r.valor);
  assert.equal(result.action.config.tagsModo,'adicionar');count++;
 }
 destinations.add(trace(r.valor).bot.id);
}
assert.equal(destinations.size,13);
assert.equal(trace('COD#055CT1C10').rule.valor,'COD#055CT1C10');
assert.equal(trace('COD#055CT2C10').rule.valor,'COD#055CT2C10');
for(const message of ['', 'Olá, gostaria de informações', 'utm_source=meta']){
 const result=trace(message);assert.equal(result.rule,undefined);assert.equal(result.action.type,'iniciar-salesbot');count++;
}
assert.ok(!graph.some(b=>b.config.acaoTipo==='definir-campo'||b.type==='encerrar-bot'));
assert.ok(!JSON.stringify(graph).includes('"regex"'));
console.log('PASS: '+count+' mensagens; 13 regras Contém, 13 ações e 13 destinos individuais; sem regex; fallback sem tags.');

