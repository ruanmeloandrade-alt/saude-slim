import fs from 'node:fs';import path from 'node:path';import {fileURLToPath} from 'node:url';
// Repository source inspection only. No network, environment variables, credentials or customer records.
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const files=[];function walk(dir){if(!fs.existsSync(dir))return;for(const e of fs.readdirSync(dir,{withFileTypes:true})){const p=path.join(dir,e.name);if(e.isDirectory())walk(p);else if(/\.(?:ts|tsx|js|mjs)$/.test(e.name))files.push(p);}}
walk(path.join(root,'src'));walk(path.join(root,'supabase/functions'));walk(path.join(root,'services'));
for(const file of files){const name=path.relative(root,file),code=fs.readFileSync(file,'utf8'),lines=code.split('\n');
 for(const match of code.matchAll(/\.from\(["']leads["']\)[\s\S]{0,160}?\.(?:insert|upsert)\(/g)){
  const line=code.slice(0,match.index).split('\n').length;
  console.log('[SLIM-IDENTITY-WRITER] '+JSON.stringify({file:name,line,source:lines.slice(Math.max(0,line-6),line+28).join('\n')}));
 }
 if(/whatsapp|lead.*(?:identity|dedup|sync)|pipeline.*server/i.test(name))console.log('[SLIM-IDENTITY-FILE] '+name);
}
console.log('[SLIM-IDENTITY-AUDIT] Source-only scan complete. No runtime changes or database calls.');
