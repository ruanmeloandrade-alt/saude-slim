import {createServerFn} from '@tanstack/react-start';
import {z} from 'zod';
import {requireSupabaseAuth} from '@/integrations/supabase/auth-middleware';
import {requireActiveWorkspace} from '@/lib/workspace-resolver.server';
import {assertSlimOperator} from '@/lib/slim-workspace-operator.server';
export const setInboxConversationStatus=createServerFn({method:'POST'}).middleware([requireSupabaseAuth]).inputValidator((v:unknown)=>z.object({leadId:z.string().uuid(),status:z.enum(['aberta','aguardando','fechada'])}).strict().parse(v)).handler(async({data,context})=>{
 const sb=context.supabase as any,workspaceId=await requireActiveWorkspace(sb,context.userId,{createIfMissing:false});
 await assertSlimOperator(sb,workspaceId,context.userId);
 const result=await sb.from('leads').update({conversation_status:data.status}).eq('workspace_id',workspaceId).eq('id',data.leadId).select('id,conversation_status').maybeSingle();
 if(result.error||result.data?.id!==data.leadId||result.data?.conversation_status!==data.status)throw new Error('Não foi possível alterar o estado da conversa.');
 return {leadId:data.leadId,status:data.status};
});
