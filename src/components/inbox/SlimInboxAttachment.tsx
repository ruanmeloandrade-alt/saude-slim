import {useEffect,useRef,useState} from 'react';
import {useQuery} from '@tanstack/react-query';
import {useServerFn} from '@tanstack/react-start';
import {Download,FileText,Loader2,RefreshCw,X} from 'lucide-react';
import {loadSlimLeadActivityMedia,resolveLeadMessageMedia} from '@/lib/leads.functions';
import {slimInboxMediaKind,slimAllowStoredMediaUrl} from '@/lib/slim-inbox-lazy-media.core';
import type {ChatMessage} from '@/lib/inbox-mock';
import {SaveInboxSticker} from './SlimInboxStickers';
import {loadSlimGroupMessageMedia} from '@/lib/slim-group-media.functions';
// Keep attachment reads bounded while the visible thread fills with real previews.
let active=0;const pending:Array<()=>void>=[];
async function readMedia<T>(task:()=>Promise<T>):Promise<T>{if(active<3)active++;else await new Promise<void>(resolve=>pending.push(resolve));try{return await task();}finally{const next=pending.shift();if(next)next();else active--;}}
export function SlimInboxAttachment({msg,mine,leadId,groupId}:{msg:ChatMessage;mine:boolean;leadId?:string;groupId?:string}){
 const root=useRef<HTMLDivElement>(null),[visible,setVisible]=useState(false),[zoom,setZoom]=useState(false),[failed,setFailed]=useState(false);
 const stored=useServerFn(loadSlimLeadActivityMedia),recover=useServerFn(resolveLeadMessageMedia);
 const groupMedia=useServerFn(loadSlimGroupMessageMedia);
 const kind=slimInboxMediaKind(msg.mediaType,msg.mimeType,msg.fileName);
 const direct=msg.mediaUrl?.startsWith('data:')?'':slimAllowStoredMediaUrl(msg.mediaUrl)??'';
 useEffect(()=>{const el=root.current;if(!el)return;if(!('IntersectionObserver' in window)){setVisible(true);return;}const observer=new IntersectionObserver(entries=>{if(entries.some(e=>e.isIntersecting)){setVisible(true);observer.disconnect();}},{rootMargin:'160px'});observer.observe(el);return()=>observer.disconnect();},[]);
 useEffect(()=>{if(!zoom)return;const close=(event:KeyboardEvent)=>{if(event.key==='Escape')setZoom(false);};window.addEventListener('keydown',close);return()=>window.removeEventListener('keydown',close);},[zoom]);
 const media=useQuery({queryKey:['inbox','attachment-preview',leadId,groupId,msg.id,msg.whatsappMessageId],enabled:Boolean(kind&&visible&&(leadId||groupId)&&!direct),staleTime:45*60_000,retry:false,queryFn:()=>readMedia(async()=>{if(groupId){const result=await groupMedia({data:{groupId,messageId:msg.id}});return result.mediaUrl;}const result=await stored({data:{leadId:leadId!,activityId:msg.id}});if(result.mediaUrl)return result.mediaUrl;if(msg.whatsappMessageId){const recovered=await recover({data:{leadId:leadId!,activityId:msg.id}});if(recovered.mediaUrl)return recovered.mediaUrl;}throw new Error('Este anexo não está disponível no histórico do WhatsApp.');})});
 const src=media.data??direct,label=msg.fileName||(kind==='image'?'Imagem':kind==='audio'?'Áudio':kind==='video'?'Vídeo':kind==='sticker'?'Figurinha':'Arquivo');
 if(!kind)return null;
 return <div ref={root} className="slim-message-attachment max-w-full" data-media-kind={kind}>
  {src&&!failed?<>
   {(kind==='image'||kind==='sticker')&&<button type="button" aria-label={kind==='sticker'?'Ampliar figurinha':'Ampliar imagem'} onClick={()=>setZoom(true)} className="block overflow-hidden rounded-xl"><img src={src} alt={label} loading="lazy" onError={()=>setFailed(true)} className={kind==='sticker'?'h-32 w-32 object-contain':'max-h-80 max-w-full object-contain'}/></button>}
   {kind==='audio'&&<audio controls preload="metadata" src={src} onError={()=>setFailed(true)} className="max-w-full w-[280px] h-11"/>}
   {kind==='video'&&<video controls playsInline preload="metadata" src={src} onError={()=>setFailed(true)} className="max-h-80 max-w-full rounded-xl"/>}
   {kind==='document'&&<a href={src} target="_blank" rel="noreferrer" download={msg.fileName||undefined} className="flex items-center gap-3 rounded-xl border p-3 text-sm" style={{borderColor:'var(--chat-divider)'}}><FileText className="h-8 w-8 shrink-0 text-primary"/><span className="min-w-0 flex-1 break-words">{label}<small className="block text-xs opacity-65">Abrir arquivo original</small></span><Download className="h-4 w-4 shrink-0"/></a>}
   {kind==='sticker'&&leadId&&<SaveInboxSticker activityId={msg.id}/>}
   {kind!=='document'&&<a href={src} target="_blank" rel="noreferrer" download={msg.fileName||undefined} className="mt-1 inline-flex items-center gap-1 text-[10px] opacity-60 hover:opacity-100"><Download className="h-3 w-3"/>Baixar {kind==='audio'?'áudio':'original'}</a>}
  </>:media.isError||failed?<div role="alert" className="max-w-[280px] rounded-xl border border-dashed p-3 text-xs space-y-2" style={{borderColor:'var(--chat-divider)'}}><strong>{label}</strong><p className="opacity-65">{failed?'O arquivo não pôde ser exibido.':media.error instanceof Error?media.error.message:'Não foi possível carregar o anexo.'}</p><button type="button" className="inline-flex items-center gap-1 text-primary" onClick={()=>{setFailed(false);void media.refetch();}}><RefreshCw className="h-3 w-3"/>Tentar novamente</button>{src&&<a href={src} target="_blank" rel="noreferrer" className="ml-3 underline">Abrir original</a>}</div>:<div className="flex h-20 min-w-[180px] items-center justify-center gap-2 rounded-xl bg-white/5 text-xs opacity-60"><Loader2 className="h-4 w-4 animate-spin"/>{kind==='audio'?'Carregando áudio...':kind==='image'?'Carregando imagem...':'Carregando anexo...'}</div>}
  {zoom&&src&&<div role="dialog" aria-modal="true" aria-label="Imagem ampliada" className="fixed inset-0 z-[999] flex items-center justify-center bg-black/90 p-4" onClick={()=>setZoom(false)}><button type="button" aria-label="Fechar imagem" className="absolute right-4 top-4 rounded-full bg-white/10 p-2 text-white" onClick={()=>setZoom(false)}><X/></button><img src={src} alt={label} className="max-h-[90dvh] max-w-[95vw] object-contain" onClick={e=>e.stopPropagation()}/></div>}
 </div>;
}
