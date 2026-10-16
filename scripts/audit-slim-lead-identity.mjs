import {execFileSync} from 'node:child_process';import {fileURLToPath} from 'node:url';
import './apply-slim-contact-identity.mjs';
// Read-only identity presentation and guarded ordinary contact creation. No production migration or repair runs from build.
execFileSync(process.execPath,['--experimental-strip-types',fileURLToPath(new URL('./test-slim-contact-identity.mjs',import.meta.url))],{stdio:'inherit'});
