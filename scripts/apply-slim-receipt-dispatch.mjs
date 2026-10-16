import fs from 'node:fs';
const file=new URL('../src/components/erp/SlimErpWorkspace.tsx',import.meta.url),mark='// SLIM_RECEIPT_DISPATCH_V1';let source=fs.readFileSync(file,'utf8');
if(!source.includes(mark)){
 const replacements=[
  ["import {SlimOrderHistory} from './SlimOrderHistory';","import {SlimOrderHistory} from './SlimOrderHistory';\nimport {SlimReceiptDispatch} from './SlimReceiptDispatch';"],
  ['<p className="text-xs text-muted-foreground">O documento permanece disponível pelo histórico. Nenhuma mensagem de WhatsApp é enviada automaticamente.</p>','<p className="text-xs text-muted-foreground">O documento permanece disponível pelo histórico. Nenhuma mensagem de WhatsApp é enviada automaticamente.</p>{pdf.status===\'confirmed\'&&<SlimReceiptDispatch key={`${workspaceId}:${pdf.orderId}`} workspaceId={workspaceId} orderId={pdf.orderId}/>}'],
 ];
 for(const[a,b]of replacements){if(source.split(a).length!==2)throw new Error('Receipt UI anchor changed: '+a.slice(0,70));source=source.replace(a,()=>b);}
 fs.writeFileSync(file,source+'\n'+mark+'\n');
}
console.log('[Receipt dispatch] Explicit-confirmation UI integrated. No document or message created by build.');
