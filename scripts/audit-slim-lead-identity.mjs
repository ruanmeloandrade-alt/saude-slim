import fs from 'node:fs';import path from 'node:path';import {fileURLToPath} from 'node:url';import {execFileSync} from 'node:child_process';
// Source inspection and a disposable database only. No production credentials or external side effects.
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const paths=['src/lib/saude-slim-orders-client.ts','src/lib/saude-slim-funnel-client.ts','src/routes/crm.leads.tsx','src/routes/inbox.leads.$leadId.tsx','src/routes/api/public/evolution/webhook.$secret.ts','src/lib/leads.functions.legacy.ts'];
for(const file of paths){if(!fs.existsSync(path.join(root,file)))throw new Error('Missing identity consumer: '+file);}
execFileSync(process.execPath,['--experimental-strip-types',path.join(root,'scripts/test-slim-contact-identity-postgres.mjs')],{stdio:'inherit'});
console.log('[SLIM-IDENTITY-AUDIT] Contact consumers located; isolated database verification completed.');
