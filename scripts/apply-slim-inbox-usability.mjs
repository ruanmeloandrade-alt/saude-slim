import fs from 'node:fs';
import ts from 'typescript';
const root=new URL('../',import.meta.url),mark='// SLIM_INBOX_USABILITY_20261103',plans=[];
function edit(path,run){const url=new URL(path,root);let s=fs.readFileSync(url,'utf8');if(s.includes(mark))return;const once=(a,b)=>{if(s.split(a).length!==2)throw Error(path+': unexpected anchor '+a.slice(0,90));s=s.replace(a,()=>b);};const section=(a,b,fn)=>{const start=s.indexOf(a),end=s.indexOf(b,start+a.length);if(start<0||end<0)throw Error(path+': section absent '+a);s=s.slice(0,start)+fn(s.slice(start,end))+s.slice(end);};run({once,section});const ast=ts.createSourceFile(path,s,ts.ScriptTarget.Latest,true,path.endsWith('.tsx')?ts.ScriptKind.TSX:ts.ScriptKind.TS);if(ast.parseDiagnostics.length)throw Error(path+': '+ast.parseDiagnostics.map(d=>ts.flattenDiagnosticMessageText(d.messageText,' ')).join(';'));plans.push([url,s+'\n'+mark+'\n']);}
edit('src/lib/leads.functions.legacy.ts',({once,section})=>{
 once('import { z } from "zod";','import { z } from "zod";\nimport {deduplicateInboxMessages,inboxConversationStatus} from "./slim-inbox-usability.core";');
 once('conversationStatus: "aberta" | "lida" | "fechada";','conversationStatus: "aberta" | "lida" | "fechada" | "aguardando";');
 once('if ((lead as { conversation_status?: string | null }).conversation_status !== "fechada") {','if (!["fechada","closed","aguardando","waiting","pending"].includes(String((lead as { conversation_status?: string | null }).conversation_status))) {');
 section('      conversationStatus: ([','\n    };\n  });',()=> '      conversationStatus: inboxConversationStatus(row.conversation_status),');
 once('activities: ((acts ?? []) as SlimProjectedActivityRow[]).map(slimProjectedActivity),','activities: deduplicateInboxMessages(((acts ?? []) as SlimProjectedActivityRow[]).map(slimProjectedActivity)),');
 once('const activities = pageRows.map(slimProjectedActivity);','const activities = deduplicateInboxMessages(pageRows.map(slimProjectedActivity));');
 once('.select("lead_id,type,occurred_at,preview_text:payload->>text,media_type:payload->>media_type,file_name:payload->>file_name")','.select("lead_id,type,occurred_at,preview_text:payload->>text,media_type:payload->>media_type,file_name:payload->>file_name,whatsapp_message_id:payload->>whatsapp_message_id,whatsapp_session_id:payload->>whatsapp_session_id")');
 once('lead_id:string;type:string;preview_text:string|null;media_type:string|null;file_name:string|null;occurred_at:string;','lead_id:string;type:string;preview_text:string|null;media_type:string|null;file_name:string|null;occurred_at:string;whatsapp_message_id?:string;whatsapp_session_id?:string;');
 once('payload:{text:row.preview_text,media_type:row.media_type,file_name:row.file_name} }','payload:{text:row.preview_text,media_type:row.media_type,file_name:row.file_name,whatsapp_message_id:row.whatsapp_message_id,whatsapp_session_id:row.whatsapp_session_id} }');
 // Preserve the complete provider media envelope; old webhook shapes are both supported.
 once('.select("message_id, session_id, raw, message_type")','.select("message_id, session_id, raw, message_type, remote_jid, from_me")');
 once('      message_type?: string | null;\n    } | null;', '      message_type?: string | null;remote_jid?:string;from_me?:boolean;\n    } | null;');
 once('        : null;\n    if (!key?.id || !key?.remoteJid) throw new Error("Chave da mídia não encontrada.");','        : raw.key && typeof raw.key === "object" ? raw.key as Record<string,unknown> : {id:waMsgId,remoteJid:w.remote_jid,fromMe:w.from_me};\n    if (!key?.id || !key?.remoteJid) throw new Error("Chave da mídia não encontrada.");');
 once('      messageType: w.message_type,','      messageType: w.message_type,\n      message: (rawData.message??raw.message) as Record<string,unknown>|undefined,');
});
edit('src/components/inbox/InboxPage.legacy.tsx',({once,section})=>{
 once('  SmilePlus,','  SmilePlus,\n  Star,');
 once('import { cn } from "@/lib/utils";',`import { cn } from "@/lib/utils";
import {deduplicateInboxMessages} from '@/lib/slim-inbox-usability.core';
import {slimInboxMediaKind} from '@/lib/slim-inbox-lazy-media.core';
import {useInboxViewValue} from '@/lib/slim-inbox-view.hooks';
import {useInboxFavorites} from '@/lib/slim-inbox-favorites.hooks';
import {SlimInboxAttachment} from './SlimInboxAttachment';
import {SlimInboxDraftAssistant} from './SlimInboxDraftAssistant';
import {SlimInboxConversationActions} from './SlimInboxConversationActions';
import {SlimInboxEmojiPicker,isSavedInboxSticker} from './SlimInboxStickers';`);
 once('  const [query, setQuery] = useState("");\n  const [tab, setTab] = useState(meta.tabs[0]);',`  const viewKey=cacheScope?\`slim:inbox:view:\${cacheScope.workspaceId}:\${cacheScope.userId}:\${channel}\`:null;
  const [query,setQuery]=useInboxViewValue(viewKey?viewKey+':search':null,'');
  const [tab,setTab]=useInboxViewValue(viewKey?viewKey+':tab':null,meta.tabs[0]);
  const favorites=useInboxFavorites(cacheScope?.workspaceId,cacheScope?.userId);`);
 once('status: c.conversationStatus === "fechada" ? ("resolvido" as const) : ("aberto" as const),','status: c.conversationStatus === "fechada" ? ("resolvido" as const) : c.conversationStatus === "aguardando" ? ("aguardando" as const) : ("aberto" as const),');
 once('        labels: Array.from(new Set([...(c.labels ?? []), ...(conversationLabels[c.id] ?? [])])),','        labels: Array.from(new Set([...(c.labels ?? []), ...(conversationLabels[c.id] ?? [])])),\n        favorite:favorites.ids(c.isGroup?"group":"lead").has(c.id),');
 once('    [conversations, conversationLabels, labelGroups, indicatorQuery.data, workspaceId, cacheScope?.userId],','    [conversations, conversationLabels, labelGroups, indicatorQuery.data, workspaceId, cacheScope?.userId, favorites],');
 once('  const mergeLeadHead =',`  useEffect(()=>{
   if(channel!=='leads'||!cacheScope||!conversationCacheReady)return;
   if(leadConvsQuery.hasNextPage&&!leadConvsQuery.isFetching&&!leadConvsQuery.isError)void leadConvsQuery.fetchNextPage();
   if(groupConvsQuery.hasNextPage&&!groupConvsQuery.isFetching&&!groupConvsQuery.isError)void groupConvsQuery.fetchNextPage();
  },[channel,cacheScope?.workspaceId,cacheScope?.userId,conversationCacheReady,leadConvsQuery.hasNextPage,leadConvsQuery.isFetching,leadConvsQuery.isError,leadConvsQuery.data?.pages.length,groupConvsQuery.hasNextPage,groupConvsQuery.isFetching,groupConvsQuery.isError,groupConvsQuery.data?.pages.length]);

  const mergeLeadHead =`);
 once('          onLoadMore={loadMoreConversations}','          onLoadMore={loadMoreConversations}\n          onToggleFavorite={(c)=>favorites.toggle({kind:c.isGroup?"group":"lead",targetId:c.id,favorite:!c.favorite})}');
 once('  onLoadMore,\n  isLoading,','  onLoadMore,\n  onToggleFavorite,\n  isLoading,');
 once('  onLoadMore: () => void;','  onLoadMore: () => void;\n  onToggleFavorite:(conv:ChatConversation)=>void;');
 once('<ConversationRow key={c.id} conv={c} channel={channel} active={c.id === selectedId} />','<ConversationRow key={c.id} conv={c} channel={channel} active={c.id === selectedId} onFavorite={()=>onToggleFavorite(c)} />');
 once('            Nenhuma conversa nesta visão.','            {hasMore?"Buscando conversas desta visão...":"Nenhuma conversa nesta visão."}');
 once('<span>{totalCount} conversas</span>','<span>{totalCount}{hasMore?"+ conversas · carregando restantes...":" conversas"}</span>');
 once('{isLoadingMore ? "Carregando…" : "Carregar mais"}','{isLoadingMore ? "Carregando automaticamente…" : "Continuar carregamento"}');
 section('function ConversationRow({','function Avatar(',part=>{
  part=part.replace('cursor-pointer block','cursor-pointer').replace('text-emerald-600','text-primary/70');
  part=part.replace('  active,','  active,\n  onFavorite,').replace('  active: boolean;','  active: boolean;\n  onFavorite:()=>void;');
  part=part.replace('      <Avatar name={conv.name}',`      <button type="button" aria-label={conv.favorite?'Remover conversa dos favoritos':'Favoritar conversa'} aria-pressed={Boolean(conv.favorite)} onClick={event=>{event.preventDefault();event.stopPropagation();onFavorite();}} className="shrink-0 self-center rounded-full p-1.5 text-muted-foreground hover:text-primary"><Star className={conv.favorite?'h-3.5 w-3.5 fill-primary text-primary':'h-3.5 w-3.5'}/></button>
      <Avatar name={conv.name}`);return part;
 });
 once('return unique.filter((a) => a.type === "message_in" || a.type === "message_out").map((a) => ({','return deduplicateInboxMessages(unique.filter((a) => a.type === "message_in" || a.type === "message_out")).map((a) => ({');
 once('      mediaDeferred: a.mediaDeferred === true,','      mediaDeferred: a.mediaDeferred === true && slimInboxMediaKind(a.mediaType,a.mimeType,a.fileName)!==null,');
 once('      mediaType: a.mediaType ?? null,','      mediaType: slimInboxMediaKind(a.mediaType,a.mimeType,a.fileName),');
 section('function MediaAttachment({','function StickerAttachment({',()=>`function MediaAttachment({msg,mine,leadId,groupId}:{msg:ChatMessage;mine:boolean;leadId?:string;groupId?:string}){return <SlimInboxAttachment msg={msg} mine={mine} leadId={leadId} groupId={groupId}/>;}

`);
 section('function MessageBubble({','function isGenericMediaLabel(',part=>part.replaceAll('relative opacity-0 group-hover/msg:opacity-100 transition-opacity','relative opacity-60 hover:opacity-100 focus-within:opacity-100 transition-opacity').replace('"group/msg flex w-full items-center gap-1.5"','"slim-inbox-message group/msg flex w-full items-center gap-1.5"').replace('"max-w-[70%] rounded-lg text-sm"','"slim-message-bubble max-w-[min(76%,680px)] rounded-2xl text-sm"'));
 once('          {canSend&&workspaceId&&cacheScope&&<SlimInboxVoiceControls','          {isLead&&<SlimInboxDraftAssistant leadId={conversation.id} draft={draft} onApply={setDraft} disabled={!canSend||sendMut.isPending||mediaMut.isPending||voiceInteraction.pending}/>}\n          {canSend&&workspaceId&&cacheScope&&<SlimInboxVoiceControls');
 once('          <ThreadMoreMenu\n            onOpenProfile=', '          <ThreadMoreMenu\n            leadId={isLead?conversation.id:undefined}\n            conversationStatus={conversation.status}\n            onOpenProfile=');
 section('function ThreadMoreMenu({','const REACTION_EMOJIS',part=>part.replace('  onOpenProfile,','  leadId,conversationStatus,\n  onOpenProfile,').replace('  onOpenProfile?: () => void;','  leadId?:string;conversationStatus?:string;\n  onOpenProfile?: () => void;').replace(/            <button\s+className="w-full flex items-center gap-2 px-3 py-2 text-xs hover:bg-white\/5"\s+disabled\s*>\s*<CheckCircle2[^]*?Marcar como resolvido\s*<\/button>/,'            {leadId&&<SlimInboxConversationActions leadId={leadId} status={conversationStatus} onClose={()=>setOpen(false)}/>}'));
 once('      const kind: "image" | "video" | "audio" | "document" = file.type.startsWith("image/")','      const kind: "image" | "video" | "audio" | "document" | "sticker" = isSavedInboxSticker(file)?"sticker":file.type.startsWith("image/")');
 section('      if (isGroupThread) {\n        return sendGroupMediaFn(', '      return sendMediaFn(',part=>part.replace('            kind,','            kind:kind==="sticker"?"image":kind,'));
 once('            <EmojiPicker\n              onPick=', '            <EmojiPicker\n              onSticker={isLead?(file)=>{setEmojiOpen(false);mediaMut.mutate({file,caption:undefined});}:undefined}\n              onPick=');
 section('function EmojiPicker({','function ThreadMoreMenu(',()=>`function EmojiPicker({onPick,onClose,onSticker}:{onPick:(emoji:string)=>void;onClose:()=>void;onSticker?:(file:File)=>void}){return <SlimInboxEmojiPicker emojis={EMOJI_SET} onPick={onPick} onClose={onClose} onSticker={onSticker}/>;}

`);
});
edit('src/components/inbox/InboxLeadRouteEnhancements.tsx',({once,section})=>{
 once('import { Bot, Loader2, Play, Square, X }','import { Bot, Loader2, Play, Square, X, Star }');
 once('type Panel =','import {useInboxFavorites} from "@/lib/slim-inbox-favorites.hooks";\nimport {favoriteFirst} from "@/lib/slim-inbox-usability.core";\n\ntype Panel =');
 once('  const choices = panel === "bots" ? state?.bots ?? [] : state?.agents ?? [];','  const automationFavorites=useInboxFavorites(workspaceId,actorId);\n  const favoriteKind=panel==="bots"?"bot":"agent";\n  const favoriteIds=automationFavorites.ids(favoriteKind);\n  const choices = favoriteFirst(panel === "bots" ? state?.bots ?? [] : state?.agents ?? [],favoriteIds);');
 section('                {choices.filter(filter).map((row) => {','                {!choices.filter(filter).length',part=>part.replace('return <button type="button" key={row.id}',`return <div key={row.id} className="flex items-center gap-1"><button type="button" aria-label={favoriteIds.has(row.id)?'Remover favorito':'Favoritar '+row.name} aria-pressed={favoriteIds.has(row.id)} disabled={automationFavorites.pending} className="rounded-lg p-2 text-primary" onClick={()=>automationFavorites.toggle({kind:favoriteKind,targetId:row.id,favorite:!favoriteIds.has(row.id)})}><Star className={favoriteIds.has(row.id)?'h-4 w-4 fill-current':'h-4 w-4'}/></button><button type="button"`).replace('</button>;','</button></div>;'));
});
edit('src/lib/leads.functions.ts',({once})=>{
 once('kind: z.enum(["image", "video", "audio", "document"]),','kind: z.enum(["image", "video", "audio", "document", "sticker"]),');
 once('    const isAudio = data.kind === "audio";','    if(data.kind==="sticker"&&data.mimeType!=="image/webp")throw new Error("Formato de figurinha inválido.");\n    const isAudio = data.kind === "audio";');
 once('    const url = isAudio','    const url = data.kind === "sticker" ? `${base}/message/sendSticker/${encodeURIComponent(credentialRow.instance_name)}` : isAudio');
 once('    const payload: Record<string, unknown> = isAudio','    const payload: Record<string, unknown> = data.kind === "sticker" ? {number:phoneDigits,sticker:mediaUrl} : isAudio');
});
for(const[url,code]of plans)fs.writeFileSync(url,code);
console.log(`[Slim Inbox] ${plans.length} scoped integrations applied; no message or automation started.`);
