// Preserve the validated 120-second/manual-save patch and extend the prebuild gate.
export { patchSalesbotSaveContract } from './apply-salesbot-save-contract.base.mjs';
import './apply-inbox-automation-contract.mjs';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
for (const file of ['test-inbox-automation-controls.mjs', 'test-saude-slim-ai-vault.mjs', 'test-saude-slim-sales-read.mjs']) {
  execFileSync(process.execPath, ['--experimental-strip-types', fileURLToPath(new URL('./' + file, import.meta.url))], { stdio: 'inherit' });
}
