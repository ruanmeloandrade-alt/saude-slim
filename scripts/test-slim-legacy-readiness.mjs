import assert from 'node:assert/strict';
import fs from 'node:fs';
import {execFileSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {legacyReconciliationReadiness,assertLegacyReconciliationReady} from '../src/lib/slim-legacy-readiness.core.ts';
const state=legacyReconciliationReadiness();let n=0;function test(name,run){run();n++;console.log('PASS legacy readiness: '+name);}
test('mutations held',()=>assert.equal(state.canReconcile,false));
test('UI reason states actual validation gate',()=>assert.match(state.message,/validação transacional final/));
test('server guard fails closed',()=>assert.throws(()=>assertLegacyReconciliationReady(),/validação transacional final/));
test('consumer cannot enable by mutating returned object',()=>{state.canReconcile=true;assert.equal(legacyReconciliationReadiness().canReconcile,false)});
test('server still held after tampering',()=>assert.throws(()=>assertLegacyReconciliationReady()));
const root=new URL('../',import.meta.url),read=p=>fs.readFileSync(new URL(p,root),'utf8');
const paths=['src/lib/slim-legacy-review.functions.ts','src/components/erp/SlimLegacyOrdersReview.tsx'];const before=paths.map(read);
test('server checks readiness before financial RPC',()=>{const code=before[0].split('export const reconcileSlimLegacySale=')[1];assert(code.indexOf('assertLegacyReconciliationReady();')>=0);assert(code.indexOf('assertLegacyReconciliationReady();')<code.indexOf("sb.rpc('slim_reconcile_legacy_sale'"))});
test('UI button respects backend readiness',()=>assert(before[1].includes('!target.canReview||!q.data?.reconciliation.canReconcile')));
execFileSync(process.execPath,[fileURLToPath(new URL('./apply-slim-legacy-readiness.mjs',import.meta.url))],{stdio:'inherit'});
test('hold transform is idempotent',()=>assert.deepEqual(paths.map(read),before));
console.log(`${n}/${n} legacy write-readiness checks passed. New legacy mutations held; normal checkout unchanged.`);
