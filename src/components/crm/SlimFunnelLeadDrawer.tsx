import {useCallback,useEffect,useRef,useState,type ReactNode} from 'react';
import {useQuery} from '@tanstack/react-query';
import {useServerFn} from '@tanstack/react-start';
import {useNavigate} from '@tanstack/react-router';
import {Loader2,ExternalLink,Inbox,RefreshCw} from 'lucide-react';
import {toast} from 'sonner';
import {Sheet,SheetContent,SheetHeader,SheetTitle,SheetDescription} from '@/components/ui/sheet';
import {SlimEmbeddedChatThread} from '@/components/inbox/InboxPage.legacy';
import {getSlimErpIdentity} from '@/lib/slim-erp-release.functions';
import {getSlimFunnelLeadSnapshot} from '@/lib/slim-funnel-drawer.functions';
import {assertFunnelSnapshotScope,CLEAN_FUNNEL_INTERACTION,funnelCloseDecision,type FunnelInteractionState} from '@/lib/slim-funnel-drawer.core';
import './slim-funnel-drawer.css';
const date=(s:string)=>Number.isFinite(Date.parse(s))?new Intl.DateTimeFormat('pt-BR',{dateStyle:'short',timeStyle:'short',timeZone:'America/Sao_Paulo'}).format(new Date(s)):'Não informado';
export function SlimFunnelLeadDrawer({leadId,onClose}:{leadId:string|null;onClose:()=>void}){
 const identify=useServerFn(getSlimErpIdentity),load=useServerFn(getSlimFunnelLeadSnapshot),navigate=useNavigate();
 const interaction=useRef<FunnelInteractionState>(CLEAN_FUNNEL_INTERACTION),initialScope=useRef<string|null>(null),[detailsExpanded,setDetailsExpanded]=useState(false);
 const identity=useQuery({queryKey:['slim-erp-identity'],queryFn:()=>identify(),enabled:!!leadId,staleTime:0,retry:1,refetchOnWindowFocus:true,refetchInterval:leadId?5000:false});
 const scope=identity.data;
 const snapshot=useQuery({queryKey:['slim','funnel-card',scope?.workspaceId,scope?.actorId,leadId],enabled:!!leadId&&!!scope&&!identity.error,staleTime:0,retry:1,refetchInterval:15000,queryFn:async()=>{
  const expected={workspaceId:scope!.workspaceId,actorId:scope!.actorId,leadId:leadId!};
  return assertFunnelSnapshotScope(await load({data:expected}),expected);
 }});
 const onInteraction=useCallback((s:FunnelInteractionState)=>{interaction.current=s;},[]);
 useEffect(()=>{interaction.current=CLEAN_FUNNEL_INTERACTION;initialScope.current=null;setDetailsExpanded(false);},[leadId]);
 useEffect(()=>{
  if(!leadId||!scope)return;const key=scope.workspaceId+':'+scope.actorId;
  if(initialScope.current&&initialScope.current!==key){onClose();return;}initialScope.current=key;
 },[leadId,scope?.workspaceId,scope?.actorId,onClose]);
 useEffect(()=>{
  if(!leadId)return;
  const before=(e:BeforeUnloadEvent)=>{if(funnelCloseDecision(interaction.current)!=='close'){e.preventDefault();e.returnValue='';}};
  window.addEventListener('beforeunload',before);return()=>window.removeEventListener('beforeunload',before);
 },[leadId]);
 function mayLeave(){const decision=funnelCloseDecision(interaction.current);if(decision==='wait'){toast.info('Aguarde a confirmação do envio ou da transcrição antes de sair desta conversa.');return false;}return decision==='close'||window.confirm('Há uma mensagem ou gravação ainda não enviada. Deseja descartá-la e sair da ficha?');}
 function close(){if(mayLeave())onClose();}
 const valid=scope&&!identity.error&&snapshot.data?.workspaceId===scope.workspaceId&&snapshot.data.actorId===scope.actorId&&snapshot.data.requestedLeadId===leadId?snapshot.data:null;
 const lead=valid?.lead,error=identity.error||snapshot.error;
 return <Sheet open={!!leadId} onOpenChange={open=>{if(!open)close();}}>
  <SheetContent side="right" className="slim-funnel-drawer" aria-label="Ficha do cliente e conversa" onCloseAutoFocus={event=>{event.preventDefault();document.querySelector<HTMLElement>('[data-slim-funnel-open-focus="true"]')?.focus();}}>
   <SheetHeader className="slim-funnel-drawer-header"><SheetTitle>{lead?.name||'Ficha do cliente'}</SheetTitle><SheetDescription>Dados do contato e atendimento na mesma conversa do Inbox.</SheetDescription>
    <div className="flex flex-wrap items-center gap-2 pt-2">
     <button type="button" className="slim-funnel-action" disabled={!lead} onClick={()=>{if(lead&&mayLeave()){void navigate({to:'/inbox/leads/$leadId',params:{leadId:lead.id}});onClose();}}}><Inbox className="h-4 w-4"/>Abrir Inbox</button>
     {lead?.whatsappWebUrl?<a className="slim-funnel-action" href={lead.whatsappWebUrl} target="_blank" rel="noopener noreferrer"><ExternalLink className="h-4 w-4"/>Abrir no WhatsApp Web</a>:<button type="button" className="slim-funnel-action" disabled title="Cadastre um telefone com DDI para abrir o WhatsApp Web."><ExternalLink className="h-4 w-4"/>WhatsApp sem número válido</button>}
     <button type="button" className="slim-funnel-action" disabled={snapshot.isFetching} onClick={()=>{void identity.refetch();void snapshot.refetch();}} aria-label="Atualizar ficha"><RefreshCw className={snapshot.isFetching?'h-4 w-4 animate-spin':'h-4 w-4'}/></button>
    </div>
   </SheetHeader>
   {!valid?(error?<div className="p-5 text-sm text-destructive" role="alert">{error instanceof Error?error.message:'Não foi possível carregar a ficha.'}<button type="button" className="ml-2 underline" onClick={()=>{void identity.refetch();void snapshot.refetch();}}>Tentar novamente</button></div>:<div className="flex flex-1 items-center justify-center gap-2 text-sm" role="status"><Loader2 className="h-4 w-4 animate-spin"/>Carregando contato e conversa...</div>):<>
    {snapshot.error&&<p role="alert" className="border-b px-5 py-2 text-xs text-destructive">A atualização falhou. Os dados abaixo são da última leitura confirmada.</p>}
    <div className="slim-funnel-drawer-grid">
     <section className="slim-funnel-details" data-expanded={detailsExpanded} aria-label="Informações do cliente">
      <button type="button" className="slim-funnel-details-toggle" aria-expanded={detailsExpanded} onClick={()=>setDetailsExpanded(v=>!v)}>{detailsExpanded?'Recolher informações':'Ver todas as informações do cliente'}</button>
      <div className="slim-funnel-details-body">
       <div className="space-y-4"><Info label="Telefone">{lead!.phone}</Info><Info label="E-mail">{lead!.email}</Info><Info label="Funil">{lead!.pipelineName}</Info><Info label="Etapa">{lead!.stageName}</Info><Info label="Origem">{lead!.sourceName}</Info><Info label="Responsável">{lead!.responsibleName}</Info><Info label="Valor da oportunidade">{new Intl.NumberFormat('pt-BR',{style:'currency',currency:'BRL'}).format(lead!.value)}</Info><Info label="Situação">{({active:'Ativo',won:'Ganho',lost:'Perdido'} as Record<string,string>)[lead!.status]??lead!.status}</Info>
        <Info label="Tags">{lead!.tags.length?<div className="flex flex-wrap gap-1">{lead!.tags.map(t=><span key={t} className="rounded border px-2 py-1 text-xs">{t}</span>)}</div>:'Nenhuma'}</Info>
        {lead!.fields.map(f=><Info key={f.id} label={f.name}>{f.value}</Info>)}<Info label="Cadastrado em">{date(lead!.createdAt)}</Info><Info label="Atualizado em">{date(lead!.updatedAt)}</Info>
        {valid.warnings.map(w=><p key={w} role="status" className="text-xs text-amber-600">{w}</p>)}
       </div>
      </div>
     </section>
     <section data-chat-surface className="slim-funnel-mini-inbox" aria-label="Conversa do cliente">
      <div className="border-b px-4 py-2 text-xs font-medium">Conversa · {lead!.name}</div>
      <SlimEmbeddedChatThread key={scope!.workspaceId+':'+scope!.actorId+':'+lead!.id} embedded conversation={valid.conversation} channel="leads" cacheScope={{workspaceId:scope!.workspaceId,userId:scope!.actorId}} workspaceId={scope!.workspaceId} onInteractionStateChange={onInteraction}/>
     </section>
    </div>
   </>}
  </SheetContent>
 </Sheet>;
}
function Info({label,children}:{label:string;children:ReactNode}){return <div><p className="text-[11px] font-medium uppercase tracking-wide text-muted-foreground">{label}</p><div className="mt-1 whitespace-pre-wrap break-words text-sm">{children??'Não informado'}</div></div>;}
