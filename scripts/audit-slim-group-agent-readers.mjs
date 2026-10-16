import fs from 'node:fs';import path from 'node:path';import {fileURLToPath} from 'node:url';
// Repository source audit only. Do not read .env, credentials, business data or the network.
const root=fileURLToPath(new URL('../',import.meta.url));
const matches=[];function walk(dir){for(const entry of fs.readdirSync(dir,{withFileTypes:true})){const name=path.join(dir,entry.name);if(entry.isDirectory())walk(name);else if(/\.(tsx?|mjs)$/.test(entry.name)){const lines=fs.readFileSync(name,'utf8').split('\n');for(let i=0;i<lines.length;i++)if(/\b(group_ai_agents|group_agent_runs|group_agent_sessions)\b/.test(lines[i]))matches.push({path:path.relative(root,name),line:i+1,symbols:[...new Set(lines[i].match(/\b(group_ai_agents|group_agent_runs|group_agent_sessions)\b/g))]});}}}
walk(path.join(root,'src'));console.log('[GROUP-AGENT-READERS] '+JSON.stringify(matches));
if(!matches.some(m=>m.path==='lib/whatsapp-groups.functions.legacy.ts'||m.path==='src/lib/whatsapp-groups.functions.legacy.ts'))throw new Error('Group-agent source consumers missing.');
