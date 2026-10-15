// Preserve the validated 120-second/manual-save patch and extend the prebuild gate.
export { patchSalesbotSaveContract } from './apply-salesbot-save-contract.base.mjs';
import './apply-inbox-automation-contract.mjs';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
execFileSync(process.execPath, ['--experimental-strip-types', fileURLToPath(new URL('./test-inbox-automation-controls.mjs', import.meta.url))], { stdio: 'inherit' });
