// Preserve the validated 120-second/manual-save patch and extend the prebuild gate.
export { patchSalesbotSaveContract } from './apply-salesbot-save-contract.base.mjs';
import './apply-inbox-automation-contract.mjs';
import './apply-slim-dashboard-contract.mjs';
import './apply-slim-audience-contract.mjs';
import './apply-slim-stage-permissions.mjs';
import './apply-slim-settings-continuation.mjs';
import './apply-slim-tracking-overview.mjs';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
for (const file of ['test-inbox-automation-controls.mjs', 'test-saude-slim-ai-vault.mjs', 'test-saude-slim-sales-read.mjs', 'test-slim-dashboard-data.mjs', 'test-slim-dashboard-contract.mjs', 'test-slim-audience-core.mjs', 'test-slim-audience-delivery.mjs', 'test-slim-audience-contract.mjs', 'test-slim-stage-permissions.mjs','test-slim-settings-validation.mjs','test-slim-settings-contract.mjs','test-slim-tracking-overview.mjs','test-slim-tracking-loader.mjs','test-slim-tracking-contract.mjs']) {
  execFileSync(process.execPath, ['--experimental-strip-types', fileURLToPath(new URL('./' + file, import.meta.url))], { stdio: 'inherit' });
}
