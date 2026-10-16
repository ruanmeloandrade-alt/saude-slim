import {createServerFn} from '@tanstack/react-start';
import {z} from 'zod';
import {attachSupabaseAuth} from '@/integrations/supabase/auth-attacher';
import {requireSupabaseAuth} from '@/integrations/supabase/auth-middleware';
import {resolveSlimContactId} from './slim-contact-identity.core';
import {describeField,normalizeContactTags,whatsappWebContactUrl,type FunnelLeadSnapshot} from './slim-funnel-drawer.core';
const Input=z.object({leadId:z.string().uuid(),workspaceId:z.string().uuid(),actorId:z.string().uuid()});
// Read-only. Opening a card never creates a contact, changes a stage or starts an automation.
export const getSlimFunnelLeadSnapshot=createServerFn({method:'POST'}).middleware([attachSupabaseAuth,requireSupabaseAuth]).inputValidator((v:unknown)=>Input.parse(v)).handler(async({data,context}):Promise<FunnelLeadSnapshot>=>{
 const db=context.supabase as any;
 async function assertScope(){
  if(context.userId!==data.actorId)throw new Error('A sessão mudou. Reabra o Funil.');
  const profile=await db.from('profiles').select('current_workspace_id').eq('id',context.userId).maybeSingle();
  if(profile.error||profile.data?.current_workspace_id!==data.workspaceId)throw new Error('A empresa ativa mudou. Reabra o Funil.');
 }
 await assertScope();
 const id=await resolveSlimContactId(db,data.workspaceId,data.leadId);
 const found=await db.from('leads').select('id,name,email,phone,phone_normalized,value,status,responsible_id,last_message_from,custom_data,tags,created_at,updated_at,pipeline_stages(name),pipelines(name),crm_sources(display_name,provider)').eq('workspace_id',data.workspaceId).eq('id',id).maybeSingle();
 if(found.error||!found.data)throw new Error('Não foi possível carregar o contato nesta empresa.');
 const row=found.data;
 if(row.source==='whatsapp_group'||row.custom_data?.technical_group_context||String(row.phone??'').includes('@'))throw new Error('Este cartão não representa uma conversa individual. Abra o grupo pelo Inbox.');
 const value=Number(row.value??0);if(!Number.isFinite(value))throw new Error('O valor cadastrado do contato é inválido.');
 const [custom,last,responsible]=await Promise.all([
  db.from('lead_custom_field_values').select('value,lead_custom_fields(id,name,field_type)').eq('workspace_id',data.workspaceId).eq('lead_id',id).order('updated_at',{ascending:false}),
  db.from('lead_activities').select('type,payload,occurred_at').eq('workspace_id',data.workspaceId).eq('lead_id',id).in('type',['message_in','message_out']).order('occurred_at',{ascending:false}).order('id',{ascending:false}).limit(1),
  row.responsible_id?db.from('profiles').select('display_name,full_name').eq('id',row.responsible_id).maybeSingle():Promise.resolve({data:null,error:null}),
 ]);
 if(last.error)throw new Error('Não foi possível conferir a conversa deste contato.');
 const warnings:string[]=[];
 if(custom.error)warnings.push('Os campos personalizados não puderam ser carregados. Os demais dados e a conversa continuam disponíveis.');
 if(responsible.error)warnings.push('Não foi possível carregar o nome do responsável.');
 const fields:Array<{id:string;name:string;value:string}>=custom.error?[]:(custom.data??[]).flatMap((r:any)=>{const f=r.lead_custom_fields;return f?[{id:f.id,name:f.name,value:describeField(r.value)}]:[];});
 // Only user-facing metadata. Integration credentials and technical flags never enter the card.
 for(const [key,label] of Object.entries({endereco:'Endereço',address:'Endereço',instagram_handle:'Instagram',facebook_url:'Facebook',notes:'Observações',observacoes:'Observações'})){
  const v=describeField(row.custom_data?.[key]);if(v&&!fields.some(f=>f.name===label&&f.value===v))fields.push({id:'metadata:'+key,name:label,value:v});
 }
 const latest=last.data?.[0],from=latest?.type==='message_in'?'them':'me';
 await assertScope();
 return {workspaceId:data.workspaceId,actorId:context.userId,requestedLeadId:data.leadId,lead:{id,name:row.name,email:row.email,phone:row.phone,value,status:row.status,stageName:row.pipeline_stages?.name??null,pipelineName:row.pipelines?.name??null,sourceName:row.crm_sources?.display_name??null,responsibleName:responsible.data?.display_name||responsible.data?.full_name||null,createdAt:row.created_at,updatedAt:row.updated_at,tags:normalizeContactTags(row.tags),fields,whatsappWebUrl:whatsappWebContactUrl(row.phone,row.phone_normalized)},conversation:{id,leadId:id,channel:'leads',name:row.name,subtitle:[row.phone,row.pipeline_stages?.name].filter(Boolean).join(' · '),isGroup:false,lastMessageFrom:from,lastMessagePreview:typeof latest?.payload?.text==='string'?latest.payload.text:'',lastMessageAt:latest?.occurred_at??row.updated_at,unreadCount:0,messages:[]},warnings};
});
