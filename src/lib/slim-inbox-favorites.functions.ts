import {createServerFn} from '@tanstack/react-start';
import {z} from 'zod';
import {requireSupabaseAuth} from '@/integrations/supabase/auth-middleware';
import {requireActiveWorkspace} from '@/lib/workspace-resolver.server';
import {slimInboxMediaKind} from './slim-inbox-lazy-media.core';
const Kind=z.enum(['bot','agent','lead','group','sticker']);
export const listInboxFavorites=createServerFn({method:'POST'}).middleware([requireSupabaseAuth]).handler(async({context})=>{
 const sb=context.supabase as any,workspaceId=await requireActiveWorkspace(sb,context.userId,{createIfMissing:false});
 const result=await sb.from('slim_inbox_favorites').select('kind,target_id').eq('workspace_id',workspaceId).eq('user_id',context.userId);
 if(result.error)throw new Error('Não foi possível consultar seus favoritos.');
 return {workspaceId,actorId:context.userId,favorites:result.data as Array<{kind:z.infer<typeof Kind>;target_id:string}>};
});
export const setInboxFavorite=createServerFn({method:'POST'}).middleware([requireSupabaseAuth]).inputValidator((v:unknown)=>z.object({kind:Kind,targetId:z.string().min(1).max(200),favorite:z.boolean()}).strict().parse(v)).handler(async({data,context})=>{
 const sb=context.supabase as any,workspaceId=await requireActiveWorkspace(sb,context.userId,{createIfMissing:false});
 if(data.kind!=='group'){
  const table=data.kind==='bot'?'salesbots':data.kind==='agent'?'conversation_ai_agents':data.kind==='sticker'?'lead_activities':'leads';
  const found=await sb.from(table).select(data.kind==='sticker'?'id,payload':'id').eq('workspace_id',workspaceId).eq('id',data.targetId).maybeSingle();
  if(found.error||!found.data)throw new Error('Item não disponível nesta empresa.');
  if(data.kind==='sticker'&&slimInboxMediaKind(found.data.payload?.media_type,found.data.payload?.mime_type)!=='sticker')throw new Error('Esta mensagem não contém uma figurinha.');
 }
 const target={workspace_id:workspaceId,user_id:context.userId,kind:data.kind,target_id:data.targetId};
 const result=data.favorite?await sb.from('slim_inbox_favorites').upsert(target,{onConflict:'workspace_id,user_id,kind,target_id',ignoreDuplicates:true}):await sb.from('slim_inbox_favorites').delete().match(target);
 if(result.error)throw new Error('Não foi possível salvar o favorito.');
 return {workspaceId,actorId:context.userId,...data};
});

export const listInboxSavedStickers=createServerFn({method:'POST'}).middleware([requireSupabaseAuth]).handler(async({context}):Promise<{workspaceId:string;actorId:string;stickers:Array<{id:string;leadId:string}>}>=>{
 const sb=context.supabase as any,workspaceId=await requireActiveWorkspace(sb,context.userId,{createIfMissing:false});
 const saved=await sb.from('slim_inbox_favorites').select('target_id').eq('workspace_id',workspaceId).eq('user_id',context.userId).eq('kind','sticker').order('created_at',{ascending:false});
 if(saved.error)throw new Error('Não foi possível consultar suas figurinhas.');
 const ids=(saved.data??[]).map((r:{target_id:string})=>r.target_id);
 if(!ids.length)return {workspaceId,actorId:context.userId,stickers:[] as Array<{id:string;leadId:string}>};
 const rows=await sb.from('lead_activities').select('id,lead_id').eq('workspace_id',workspaceId).in('id',ids);
 if(rows.error)throw new Error('Não foi possível consultar as figurinhas salvas.');
 const byId=new Map((rows.data??[]).map((r:{id:string;lead_id:string})=>[r.id,r.lead_id]));
 return {workspaceId,actorId:context.userId,stickers:ids.filter((id:string)=>byId.has(id)).map((id:string)=>({id,leadId:byId.get(id) as string}))};
});
