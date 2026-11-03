type Activity={id:string;type?:string;from?:string;occurredAt?:string;sentAt?:string;whatsappMessageId?:string|null;whatsappSessionId?:string|null;whatsappRemoteJid?:string|null;mediaType?:string|null;mediaUrl?:string|null;mediaDeferred?:boolean;reactions?:unknown;deletedForMe?:boolean;deletedForAll?:boolean;text?:string|null};
/** Same provider message, same thread/session. Similar text is never an identity. */
export function deduplicateInboxMessages<T extends Activity>(rows:readonly T[]):T[]{
 const sessions=new Map<string,Set<string>>();
 for(const row of rows)if(row.whatsappMessageId&&row.whatsappSessionId){const s=sessions.get(row.whatsappMessageId)??new Set<string>();s.add(row.whatsappSessionId);sessions.set(row.whatsappMessageId,s);}
 const merged=new Map<string,T>();
 for(const row of rows){
  const known=row.whatsappMessageId?sessions.get(row.whatsappMessageId):undefined;
  const session=row.whatsappSessionId||(known?.size===1?[...known][0]:'unknown');
  const key=row.whatsappMessageId?`${row.type??row.from??''}:${session}:${row.whatsappMessageId}`:`activity:${row.id}`;
  const previous=merged.get(key);
  if(!previous){merged.set(key,row);continue;}
  // Prefer an actual file/caption but retain deletion and reaction updates from either record.
  const richer=(value:Activity)=>(value.mediaUrl?8:0)+(value.mediaType&&value.mediaType!=='conversation'?4:0)+(value.text?2:0);
  const winner=richer(row)>richer(previous)?row:previous,other=winner===row?previous:row;
  merged.set(key,{...other,...winner,deletedForMe:previous.deletedForMe||row.deletedForMe,deletedForAll:previous.deletedForAll||row.deletedForAll,reactions:Array.isArray(row.reactions)&&row.reactions.length?row.reactions:previous.reactions} as T);
 }
 return [...merged.values()].sort((a,b)=>Date.parse(a.occurredAt??a.sentAt??'')-Date.parse(b.occurredAt??b.sentAt??''));
}
export function inboxConversationStatus(value:unknown):'aberta'|'lida'|'fechada'|'aguardando'{
 const s=String(value??'').toLowerCase();
 if(['fechada','closed','resolved','resolvido'].includes(s))return 'fechada';
 if(['aguardando','waiting','pending'].includes(s))return 'aguardando';
 if(['lida','read'].includes(s))return 'lida';
 return 'aberta';
}
export function favoriteFirst<T extends{id:string;name:string}>(rows:readonly T[],ids:ReadonlySet<string>):T[]{return [...rows].sort((a,b)=>Number(ids.has(b.id))-Number(ids.has(a.id))||a.name.localeCompare(b.name,'pt-BR'));}
