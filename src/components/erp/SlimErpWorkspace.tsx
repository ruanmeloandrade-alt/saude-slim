import {useEffect,useMemo,useRef,useState} from 'react';
import {Link} from '@tanstack/react-router';
import {useServerFn} from '@tanstack/react-start';
import {useQuery,useQueryClient} from '@tanstack/react-query';
import {Dialog,DialogContent,DialogHeader,DialogTitle,DialogDescription} from '@/components/ui/dialog';
import {getSlimErpIdentity,getSlimErpContext,getSlimErpHistory,confirmSlimErpOrder,lookupSlimErpOrder,cancelSlimErpOrder,getSlimOrderReceipt} from '@/lib/slim-erp-release.functions';
import {verifyCheckoutReceipt,type ConfirmedCheckout} from '@/lib/slim-checkout.core';
import {CheckoutRejected,type CheckoutTransport} from '@/lib/slim-checkout-session.core';
import {checkoutJournal} from '@/lib/slim-checkout-journal.core';
import {buildOrderReadModel,formatOrderCents,type OrderSnapshot} from '@/lib/slim-order-read.core';
import {erpReadableError} from '@/lib/slim-erp-release.core';
import {SlimCheckout} from './SlimCheckout';
import {SlimOrderHistory} from './SlimOrderHistory';
import {SlimOrderChangeDialog,type SlimOrderChangeTarget} from './SlimOrderChangeDialog';
import type {OrderChangeResult} from '@/lib/slim-order-changes.core';

type Mode='checkout'|'history'|'summary';
export function SlimErpWorkspace({mode}:{mode:Mode}) {
 const identify=useServerFn(getSlimErpIdentity);
 const identity=useQuery({queryKey:['slim-erp-identity'],queryFn:()=>identify(),staleTime:0,retry:1,refetchInterval:30000,refetchOnWindowFocus:true});
 if(identity.error||!identity.data)return <section className="rounded-xl border bg-card p-5"><h2 className="font-semibold">Gestão ERP</h2><p role={identity.error?'alert':'status'} className="mt-3 text-sm">{identity.error?erpReadableError(identity.error):'Identificando a empresa ativa...'}</p>{identity.error&&<button type="button" className="mt-3 text-sm underline" onClick={()=>identity.refetch()}>Tentar novamente</button>}</section>;
 return <Workspace key={`${identity.data.workspaceId}:${identity.data.actorId}:${mode}`} mode={mode} workspaceId={identity.data.workspaceId} actorId={identity.data.actorId}/>;
}
function Workspace({mode,workspaceId,actorId}:{mode:Mode;workspaceId:string;actorId:string}) {
 const qc=useQueryClient();
 const loadContext=useServerFn(getSlimErpContext),loadHistory=useServerFn(getSlimErpHistory),confirm=useServerFn(confirmSlimErpOrder),lookup=useServerFn(lookupSlimErpOrder),cancelOrder=useServerFn(cancelSlimErpOrder),loadReceipt=useServerFn(getSlimOrderReceipt);
 const contextQ=useQuery({queryKey:['slim-erp-context',workspaceId,actorId],queryFn:()=>loadContext({data:{workspaceId}}),enabled:mode==='checkout',retry:1,staleTime:0});
 const historyQ=useQuery({queryKey:['slim-erp-orders',workspaceId,actorId],queryFn:()=>loadHistory({data:{workspaceId}}),enabled:mode!=='checkout',retry:1,staleTime:0,refetchInterval:15000});
 const [checkoutKey,setCheckoutKey]=useState(0),[receipt,setReceipt]=useState<ConfirmedCheckout|null>(null);
 const [notice,setNotice]=useState(''),[operationError,setOperationError]=useState(''),[cancelBusy,setCancelBusy]=useState<string|null>(null);
 const [changeTarget,setChangeTarget]=useState<SlimOrderChangeTarget|null>(null),[changesLocked,setChangesLocked]=useState(true);
 const [recovering,setRecovering]=useState(mode==='checkout'),[pendingRequest,setPendingRequest]=useState('');
 const [pdf,setPdf]=useState<Awaited<ReturnType<typeof loadReceipt>>|null>(null),[pdfBusy,setPdfBusy]=useState(false);
 const live=useRef(true);useEffect(()=>{live.current=true;return()=>{live.current=false;};},[]);
 const journal=()=>checkoutJournal(window.localStorage,workspaceId,actorId);
 const refresh=()=>qc.invalidateQueries({predicate:q=>q.queryKey[0]!=='slim-erp-identity'});
 function clearJournal(id:string){try{journal().clear(id);}catch{if(live.current)setNotice('O pedido foi confirmado, mas a referência local não pôde ser limpa. Consulte o histórico antes de repetir.');}}
 async function recover(request?:string) {
  setRecovering(true);setOperationError('');
  try {
   const id=request||journal().read()?.requestId;if(!id){setPendingRequest('');return;}
   setPendingRequest(id);
   const result=await lookup({data:{workspaceId,requestId:id}});if(!live.current)return;
   if(result.state==='confirmed'){clearJournal(id);setPendingRequest('');setReceipt(result.receipt);setNotice(`Pedido ${result.receipt.number} recuperado sem criar outra venda.`);await refresh();}
   else if(result.state==='rejected'){clearJournal(id);setPendingRequest('');setOperationError(result.message);}
   else setOperationError('Resultado ainda não confirmado. A referência foi preservada; consulte novamente antes de criar outra venda.');
  }catch(e){if(live.current)setOperationError(erpReadableError(e));}
  finally{if(live.current)setRecovering(false);}
 }
 useEffect(()=>{if(mode==='checkout')void recover();},[]);
 const transport=useMemo<CheckoutTransport>(()=>({
  confirm:async(requestId,quote)=>{
   try{journal().begin(requestId);}catch(e){throw new CheckoutRejected(erpReadableError(e));}
   const response=await confirm({data:{workspaceId,requestId,quote}});
   if(response.state==='rejected'){clearJournal(requestId);throw new CheckoutRejected(response.message);}
   const verified=verifyCheckoutReceipt(quote,requestId,response.receipt);clearJournal(requestId);return verified;
  },
  lookup:async(requestId)=>{const result=await lookup({data:{workspaceId,requestId}});if(result.state==='confirmed'||result.state==='rejected')clearJournal(requestId);return result;},
 }),[workspaceId,actorId,confirm,lookup]);
 async function openReceipt(orderId:string) {
  if(pdfBusy)return;setPdfBusy(true);setOperationError('');
  try{const result=await loadReceipt({data:{workspaceId,orderId}});if(live.current)setPdf(result);}
  catch(e){if(live.current)setOperationError(`O pedido permanece registrado. Documento: ${erpReadableError(e)}`);}
  finally{if(live.current)setPdfBusy(false);}
 }
 async function onConfirmed(value:ConfirmedCheckout){setReceipt(value);await refresh();await openReceipt(value.orderId);}
 function openChange(order:OrderSnapshot,operation:'edit'|'delete'){
  if(changesLocked||cancelBusy||order.change||order.workspaceId!==workspaceId||(operation==='edit'&&order.status!=='confirmed'))return;
  setChangeTarget({orderId:order.orderId,operation});setOperationError('');
 }
 async function onOrderChanged(value:OrderChangeResult){
  if(!live.current||value.workspaceId!==workspaceId||value.actorId!==actorId)return;
  setNotice(value.state==='closed'?'Tentativa de alteração encerrada sem repetir a operação.':value.operation==='delete'?'Pedido excluído da lista operacional. Original e documento disponíveis em Alterações.':value.replacementStatus==='cancelled'?'Edição recuperada. O pedido substituto está cancelado; confira o histórico.':`Pedido revisado${value.receipt?`: ${value.receipt.number}`:''}. O original permanece na aba Alterações.`);
  await refresh();
 }
 async function cancel(order:OrderSnapshot){
  if(cancelBusy||changesLocked||order.change)return;
  const reason=window.prompt(`Cancelar ${order.number} e repor o estoque? Informe o motivo. Esta ação não executa reembolso bancário.`);
  if(!reason?.trim())return;setCancelBusy(order.orderId);setOperationError('');
  try{await cancelOrder({data:{workspaceId,orderId:order.orderId,reason:reason.trim()}});setNotice(`Pedido ${order.number} cancelado; estorno de estoque registrado.`);await refresh();}
  catch(e){setOperationError(erpReadableError(e));}finally{setCancelBusy(null);}
 }
 function download(){
  if(!pdf)return;
  try{const bytes=Uint8Array.from(atob(pdf.pdfBase64),c=>c.charCodeAt(0));const url=URL.createObjectURL(new Blob([bytes],{type:'application/pdf'}));const a=document.createElement('a');a.href=url;a.download=pdf.filename;document.body.appendChild(a);a.click();a.remove();window.setTimeout(()=>URL.revokeObjectURL(url),1000);}
  catch{setOperationError('Não foi possível abrir o PDF. O pedido não foi alterado.');}
 }
 const summary=useMemo(()=>{
  if(mode!=='summary'||!historyQ.data||historyQ.error)return null;
  try{return {model:buildOrderReadModel(historyQ.data,workspaceId,{view:'operational'}),error:''};}catch(e){return {model:null,error:erpReadableError(e)};}
 },[mode,historyQ.data,historyQ.error,workspaceId]);
 const totals=summary?.model?.totals;
 return <div className="space-y-4">
  {notice&&<p role="status" className="rounded-lg border p-3 text-sm">{notice}</p>}
  {operationError&&<p role="alert" className="rounded-lg border border-destructive/40 p-3 text-sm text-destructive">{operationError}</p>}
  <SlimOrderChangeDialog workspaceId={workspaceId} actorId={actorId} target={changeTarget} onClose={()=>setChangeTarget(null)} onCompleted={onOrderChanged} onDocument={openReceipt} onLockChange={setChangesLocked}/>
  {mode==='summary'?<section className="rounded-xl border bg-card p-5 space-y-4"><header className="flex flex-wrap items-center justify-between gap-3"><div><h2 className="text-lg font-semibold">Vendas e recebimentos · Gestão ERP</h2><p className="text-xs text-muted-foreground">Todo o histórico de pedidos ERP. Mesma origem de dados do Histórico de Vendas.</p></div><div className="flex gap-3 text-sm"><Link to="/saude-slim" className="underline">Ver pedidos</Link><button type="button" className="underline" onClick={()=>historyQ.refetch()}>Atualizar</button></div></header>
   {historyQ.error||summary?.error?<p role="alert" className="text-sm text-destructive">{summary?.error||erpReadableError(historyQ.error)}</p>:!totals?<p role="status">Carregando os pedidos...</p>:<><div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">{[['Pedidos confirmados',String(totals.confirmedCount)],['Valor dos pedidos',formatOrderCents(totals.totalCents)],['Recebimento informado',formatOrderCents(totals.receivedDeclaredCents)],['Pagamento pendente',formatOrderCents(totals.pendingPaymentCents)]].map(([label,value])=><div key={label} className="rounded-lg border bg-background p-4"><p className="text-xs text-muted-foreground">{label}</p><p className="mt-2 text-xl font-semibold tabular-nums">{value}</p></div>)}</div><dl className="grid gap-3 text-sm sm:grid-cols-3">{[['Produtos',totals.subtotalCents],['Descontos nos produtos',totals.discountCents],['Frete dos pedidos confirmados',totals.shippingCents]].map(([label,value])=><div key={String(label)} className="rounded-lg border p-3"><dt className="text-xs text-muted-foreground">{label}</dt><dd className="mt-1 font-medium tabular-nums">{formatOrderCents(Number(value))}</dd></div>)}</dl><p className="text-xs text-muted-foreground">{totals.units} unidades vendidas · {totals.cancelledCount} cancelados, fora dos totais. Recebimento informado não é confirmação bancária.</p></>}
  </section>:mode==='history'?<><div className="flex justify-end gap-3 text-sm"><Link to="/pedidos" className="rounded-md bg-primary px-4 py-2 text-primary-foreground">Novo pedido</Link><button type="button" className="underline" onClick={()=>historyQ.refetch()}>Atualizar</button></div><SlimOrderHistory workspaceId={workspaceId} response={historyQ.error?null:historyQ.data} loading={historyQ.isLoading} error={historyQ.error?erpReadableError(historyQ.error):undefined} onDocument={o=>openReceipt(o.orderId)} onCancel={cancel} onEdit={o=>openChange(o,'edit')} onDelete={o=>openChange(o,'delete')} cancelBusy={cancelBusy||(changesLocked?'change-pending':null)}/></>:
   recovering||pendingRequest?<section className="rounded-xl border bg-card p-5 space-y-3"><h1 className="text-xl font-semibold">Conferir tentativa anterior</h1><p role="status" className="text-sm">{recovering?'Consultando antes de liberar novo pedido...':'A confirmação anterior precisa ser verificada.'}</p><p className="break-all text-xs">{pendingRequest}</p><button type="button" disabled={recovering} className="rounded-md border px-4 py-2 text-sm" onClick={()=>void recover(pendingRequest)}>Consultar sem reenviar</button><Link to="/saude-slim" className="ml-3 text-sm underline">Abrir histórico</Link></section>:
   <>{receipt&&<section className="flex flex-wrap items-center gap-3 rounded-lg border border-primary/30 bg-primary/5 p-4"><strong className="text-sm">Pedido {receipt.number} confirmado</strong><button type="button" disabled={pdfBusy} className="text-sm underline" onClick={()=>void openReceipt(receipt.orderId)}>Documento PDF</button><Link to="/saude-slim" className="text-sm underline">Conferir histórico</Link><button type="button" className="rounded-md border px-3 py-2 text-sm" onClick={async()=>{await contextQ.refetch();setReceipt(null);setCheckoutKey(n=>n+1);}}>Iniciar outro pedido</button></section>}
    <SlimCheckout key={`${workspaceId}:${checkoutKey}`} workspaceId={workspaceId} catalog={contextQ.data?.workspaceId===workspaceId?contextQ.data.catalog:[]} customers={contextQ.data?.workspaceId===workspaceId?contextQ.data.customers:[]} loading={contextQ.isLoading} loadError={contextQ.error?erpReadableError(contextQ.error):contextQ.data&&contextQ.data.workspaceId!==workspaceId?'A empresa mudou. Reabra o checkout.':undefined} transport={transport} onConfirmed={onConfirmed}/></>}
  <Dialog open={Boolean(pdf)} onOpenChange={open=>{if(!open)setPdf(null);}}><DialogContent className="max-w-lg"><DialogHeader><DialogTitle>Documento do pedido {pdf?.number}</DialogTitle><DialogDescription>Comprovante comercial produzido a partir dos dados registrados na venda. Não é uma nota fiscal autorizada.</DialogDescription></DialogHeader>{pdf&&<div className="space-y-3">{pdf.status==='cancelled'&&<p className="text-sm text-destructive">Este pedido foi cancelado. O PDF preserva o registro original.</p>}<button type="button" className="rounded-md bg-primary px-4 py-2 text-sm text-primary-foreground" onClick={download}>Baixar PDF</button><p className="text-xs text-muted-foreground">O documento permanece disponível pelo histórico. Nenhuma mensagem de WhatsApp é enviada automaticamente.</p></div>}</DialogContent></Dialog>
 </div>;
}
