/**
 * Núcleo funcional do funil Saúde Slim no Supabase Auth/RLS.
 * Mantém os DTOs da interface original. A execução de SalesBots e dos gatilhos
 * continua dependendo de backend separado, nunca roda no browser.
 */
import { supabase } from "@/integrations/supabase/client";
const sb=supabase as any;
async function ctx(){
  const {data:auth,error:err}=await supabase.auth.getUser();
  if(err||!auth.user)throw new Error("Faça login na Saúde Slim.");
  const uid=auth.user.id;
  const {data:prof,error:e}=await sb.from("profiles").select("current_workspace_id")
    .eq("id",uid).maybeSingle();
  if(e||!prof?.current_workspace_id)throw new Error("Workspace indisponível.");
  const ws=prof.current_workspace_id as string;
  const {data:m,error:em}=await sb.from("workspace_members").select("role")
    .eq("user_id",uid).eq("workspace_id",ws).maybeSingle();
  if(em||!m)throw new Error("Não há acesso autorizado ao funil.");
  return {ws,uid,role:String(m.role)};
}
const rows=(res:any):any[]=>{
  if(res.error)throw new Error(res.error.message);
  return res.data??[];
};
const requiresEditor=(role:string)=>{
  if(!["owner","admin"].includes(role))
    throw new Error("Sem permissão para modificar o funil.");
};
export async function listSlimSources(){
  const {ws}=await ctx();
  const sources=rows(await sb.from("crm_sources").select("id,provider,display_name,is_default")
    .eq("workspace_id",ws).order("is_default",{ascending:false}));
  return {sources};
}
export async function listSlimFunnels({data}:{data:{crmSourceId:string}}){
  const {ws}=await ctx();
  const linked=rows(await sb.from("crm_source_funnels").select("pipeline_id")
    .eq("workspace_id",ws).eq("crm_source_id",data.crmSourceId));
  const ids=linked.map((x:any)=>x.pipeline_id);
  if(!ids.length)return {funnels:[]};
  const [p,st,lr]=await Promise.all([
    sb.from("pipelines").select("id,name,position").eq("workspace_id",ws).in("id",ids).order("position"),
    sb.from("pipeline_stages").select("id,pipeline_id,name,color,description,position,created_at")
      .eq("workspace_id",ws).in("pipeline_id",ids).order("position"),
    sb.from("leads").select("id,pipeline_id,stage_id,name,value,created_at,email,phone,tags,last_message_from,company_id")
      .eq("workspace_id",ws).eq("crm_source_id",data.crmSourceId).eq("status","active").limit(5000),
  ]);
  const pipes=rows(p),stages=rows(st),leads=rows(lr);
  return {funnels:pipes.map((pipe:any)=>({
    id:pipe.id,name:pipe.name,
    stages:stages.filter((stage:any)=>stage.pipeline_id===pipe.id).map((stage:any)=>({
      id:stage.id,name:stage.name,color:stage.color??null,
      description:stage.description??null,
      status:/ganh|venda/i.test(stage.name)?"ganha":/perdid/i.test(stage.name)?"perdida":"aberta",
      leads:leads.filter((lead:any)=>lead.stage_id===stage.id).map((lead:any)=>({
        id:lead.id,name:lead.name,value:Number(lead.value??0),
        lastMessageFrom:lead.last_message_from??"none",
        companyId:lead.company_id,createdAt:lead.created_at,
        email:lead.email,phone:lead.phone,
        tags:Array.isArray(lead.tags)?lead.tags:[],
      }))
    }))
  }))};
}
export async function listSlimUsers(){
  const {ws}=await ctx();
  const members=rows(await sb.from("workspace_members").select("user_id")
    .eq("workspace_id",ws));
  const ids=members.map((m:any)=>m.user_id);
  if(!ids.length)return {users:[]};
  const profiles=rows(await sb.from("profiles").select("id,display_name,full_name").in("id",ids));
  const byId=new Map(profiles.map((p:any)=>[p.id,p]));
  return {users:ids.map((id:string)=>({
    id,name:byId.get(id)?.display_name||byId.get(id)?.full_name||"Usuário"
  }))};
}
export async function moveSlimLead({data}:{data:{leadId:string;toStageId:string}}){
  const {ws,role}=await ctx();requiresEditor(role);
  const {data:stage,error:stageErr}=await sb.from("pipeline_stages").select("pipeline_id,name")
    .eq("workspace_id",ws).eq("id",data.toStageId).maybeSingle();
  if(stageErr||!stage)throw new Error("Etapa inválida.");
  const {data:lead,error:leadErr}=await sb.from("leads").select("id,company_id")
    .eq("workspace_id",ws).eq("id",data.leadId).maybeSingle();
  if(leadErr||!lead)throw new Error("Cliente não encontrado no workspace.");
  let q=sb.from("leads").update({
    stage_id:data.toStageId,pipeline_id:stage.pipeline_id,
    last_message_from:"us",
    updated_at:new Date().toISOString(),
  }).eq("workspace_id",ws);
  if(lead.company_id)q=q.eq("company_id",lead.company_id);
  else q=q.eq("id",data.leadId);
  const {error}=await q;
  if(error)throw new Error(error.message);
  return {
    ok:true,automations:[] as Array<{actionId:string;title:string;ok:boolean}>,
    backendPending:true,
  };
}
