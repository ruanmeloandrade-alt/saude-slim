import {useEffect,useRef,useState} from 'react';
import {calculateCheckout,formatCheckoutCents,type CatalogItem,type CheckoutDraft,type CheckoutQuote,type ConfirmedCheckout} from '../../lib/slim-checkout.core';
import {createCheckoutSession,type CheckoutTransport} from '../../lib/slim-checkout-session.core';
import {parseMoneyCents} from '../../lib/slim-money.core';
type CustomerOption={id:string;name:string;phone?:string;email?:string};
type Props={workspaceId:string;catalog:CatalogItem[];customers:CustomerOption[];loadError?:string;loading?:boolean;transport:CheckoutTransport|null;onConfirmed:(receipt:ConfirmedCheckout)=>void|Promise<void>};
const methods=[['pix','PIX'],['cash','Dinheiro'],['debit_card','Cartão de débito'],['credit_card','Cartão de crédito'],['bank_transfer','Transferência'],['boleto','Boleto'],['other','Outro']] as const;
/** Unwired component: mount only after an authorized persistent ledger passes acceptance. */
export function SlimCheckout({workspaceId,catalog,customers,loading=false,loadError,transport,onConfirmed}:Props){
 const [kind,setKind]=useState<'existing'|'new'>('existing');const [customerId,setCustomerId]=useState('');
 const [name,setName]=useState('');const [email,setEmail]=useState('');const [phone,setPhone]=useState('');
 const [search,setSearch]=useState('');const [items,setItems]=useState<Array<{productId:string;quantity:number}>>([]);
 const [discountKind,setDiscountKind]=useState<'amount'|'percent'>('amount');const [discountText,setDiscountText]=useState('0');
 const [fulfillmentMode,setFulfillmentMode]=useState<'pickup'|'delivery'>('pickup');const [shippingText,setShippingText]=useState('0');
 const [delivery,setDelivery]=useState({recipient:'',phone:'',postalCode:'',street:'',number:'',complement:'',neighborhood:'',city:'',state:'',notes:''});
 const [method,setMethod]=useState<CheckoutDraft['payment']['method']>('pix');const [paymentStatus,setPaymentStatus]=useState<'pending'|'paid'>('pending');
 const [installments,setInstallments]=useState(1);const [notes,setNotes]=useState('');const [error,setError]=useState('');const [notice,setNotice]=useState('');
 const [session,setSession]=useState<ReturnType<typeof createCheckoutSession>|null>(null);const [,render]=useState(0);
 const [busy,setBusy]=useState(false);const notified=useRef('');const currentWorkspace=useRef(workspaceId);const liveWorkspace=useRef(workspaceId);liveWorkspace.current=workspaceId;
 const state=session?.get();const locked=Boolean(state&&state.state!=='rejected');
 const scopeChanged=currentWorkspace.current!==workspaceId;
 useEffect(()=>{if(scopeChanged)setError('A empresa ativa mudou. Reabra o checkout para evitar misturar dados.');},[scopeChanged]);
 function quote():CheckoutQuote{
  if(scopeChanged)throw new Error('Reabra o checkout na empresa ativa.');
  if(kind==='existing'&&!customers.some(c=>c.id===customerId))throw new Error('Selecione um cliente da lista carregada.');
  return calculateCheckout(workspaceId,{customer:kind==='existing'?{kind,id:customerId}:{kind,name,email,phone},items,discount:discountKind==='amount'?{kind:'amount',cents:parseMoneyCents(discountText)}:{kind:'percent',basisPoints:parseMoneyCents(discountText,10000)},payment:{method,status:paymentStatus,installments},notes,fulfillment:fulfillmentMode==='pickup'?{mode:'pickup'}:{mode:'delivery',...delivery},shippingCents:fulfillmentMode==='delivery'?parseMoneyCents(shippingText):0},catalog);
 }
 let preview:CheckoutQuote|null=null;try{preview=state?.quote??quote();}catch{/* Validation appears when reviewing, not as a fabricated zero total. */}
 function review(){setError('');setNotice('');try{if(!transport)throw new Error('A finalização depende da gravação transacional do ERP, ainda não disponível. Nenhuma venda foi enviada.');setSession(createCheckoutSession(quote(),transport));}catch(e){setError(e instanceof Error?e.message:'Pedido inválido.');}}
 async function apply(action:'approve'|'reconcile'){
  if(!session||busy||scopeChanged)return;setBusy(true);setError('');
  try{
   await session[action]();const result=session.get();render(x=>x+1);
   if(result.receipt&&notified.current!==result.receipt.orderId){notified.current=result.receipt.orderId;
    if(liveWorkspace.current!==result.receipt.workspaceId){setNotice('Pedido confirmado na empresa original. Reabra o checkout para visualizar a empresa atual.');return;}
    try{await onConfirmed(result.receipt);}catch{setNotice('Pedido confirmado. A atualização da tela falhou; não finalize novamente.');}
   }
  }catch(e){setError(e instanceof Error?e.message:'Não foi possível confirmar.');}finally{setBusy(false);}
 }
 const field='w-full rounded-md border border-input bg-background p-2 text-sm';
 return <div className="space-y-5" aria-busy={loading||busy}>
  <header><h1 className="text-2xl font-semibold">Checkout de pedido</h1><p className="mt-1 text-sm text-muted-foreground">Revise o cliente, os produtos, a entrega e o pagamento antes de confirmar.</p></header>
  {!transport&&<p role="status" className="rounded-lg border border-amber-500/40 bg-amber-500/5 p-3 text-sm">Preparação do pedido disponível. A confirmação só será liberada após a implantação e validação do registro transacional.</p>}
  {loadError&&<p role="alert" className="text-destructive">{loadError}</p>}{loading&&<p>Carregando clientes e catálogo...</p>}
  <div className="grid min-w-0 gap-5 xl:grid-cols-[minmax(0,1fr)_340px]">
   <fieldset disabled={locked||loading||Boolean(loadError)||scopeChanged} className="min-w-0 space-y-5">
    <section className="rounded-xl border bg-card p-5 space-y-3"><h2 className="font-semibold">Cliente</h2>
     <div className="flex gap-4 text-sm"><label><input type="radio" checked={kind==='existing'} onChange={()=>setKind('existing')}/> Cliente cadastrado</label><label><input type="radio" checked={kind==='new'} onChange={()=>setKind('new')}/> Novo cliente</label></div>
     {kind==='existing'?<label className="block text-sm">Cliente<select className={field} value={customerId} onChange={e=>setCustomerId(e.target.value)}><option value="">Selecione</option>{customers.map(c=><option key={c.id} value={c.id}>{c.name}{c.phone?` · ${c.phone}`:''}</option>)}</select><span className="text-xs text-muted-foreground">O pedido usará o cadastro selecionado, sem duplicar o cliente.</span></label>:<div className="grid gap-3 sm:grid-cols-2"><label className="sm:col-span-2 text-sm">Nome<input className={field} value={name} onChange={e=>setName(e.target.value)} maxLength={160}/></label><label className="text-sm">E-mail<input type="email" className={field} value={email} onChange={e=>setEmail(e.target.value)} maxLength={254}/></label><label className="text-sm">Telefone<input type="tel" className={field} value={phone} onChange={e=>setPhone(e.target.value)} maxLength={40}/></label></div>}
    </section>
    <section className="rounded-xl border bg-card p-5 space-y-3"><h2 className="font-semibold">Produtos</h2><input aria-label="Buscar produto" className={field} placeholder="Nome ou SKU" value={search} onChange={e=>setSearch(e.target.value)}/>
     <div className="max-h-52 overflow-y-auto divide-y">{catalog.filter(p=>p.workspaceId===workspaceId&&p.active&&`${p.name} ${p.sku}`.toLocaleLowerCase('pt-BR').includes(search.toLocaleLowerCase('pt-BR'))).map(p=><div key={p.id} className="flex items-center justify-between gap-3 py-3"><div className="min-w-0"><strong className="block truncate text-sm">{p.name}</strong><span className="text-xs text-muted-foreground">{formatCheckoutCents(p.priceCents)} · Estoque: {p.stock}</span></div><button type="button" disabled={p.stock<=0||(items.find(i=>i.productId===p.id)?.quantity??0)>=p.stock} className="rounded-md border px-3 py-1.5 text-sm disabled:opacity-40" onClick={()=>setItems(rows=>rows.some(i=>i.productId===p.id)?rows.map(i=>i.productId===p.id?{...i,quantity:i.quantity+1}:i):[...rows,{productId:p.id,quantity:1}])}>Adicionar</button></div>)}</div>
     <h3 className="pt-2 text-sm font-medium">Carrinho ({items.length} itens)</h3>{!items.length&&<p className="text-sm text-muted-foreground">Adicione um produto para começar.</p>}
     <div className="divide-y">{items.map(item=>{const p=catalog.find(p=>p.id===item.productId&&p.workspaceId===workspaceId);return <div key={item.productId} className="grid grid-cols-[minmax(0,1fr)_80px_auto] items-center gap-3 py-3"><div className="min-w-0"><span className="block truncate text-sm">{p?.name??'Produto indisponível'}</span>{p&&<span className="text-xs">{formatCheckoutCents(p.priceCents)} por unidade</span>}</div><input aria-label={`Quantidade de ${p?.name??'produto'}`} type="number" min="1" step="1" max={p?.stock} className={field} value={item.quantity||''} onChange={e=>setItems(rows=>rows.map(i=>i.productId===item.productId?{...i,quantity:Number(e.target.value)}:i))}/><button type="button" aria-label={`Remover ${p?.name??'produto'}`} className="text-sm text-destructive" onClick={()=>setItems(rows=>rows.filter(i=>i.productId!==item.productId))}>Remover</button></div>;})}</div>
    </section>
    <section className="rounded-xl border bg-card p-5 space-y-3"><h2 className="font-semibold">Retirada ou entrega</h2>
     <div className="flex flex-wrap gap-4 text-sm"><label><input type="radio" name="slim-fulfillment" aria-label="Retirada" checked={fulfillmentMode==='pickup'} onChange={()=>{setFulfillmentMode('pickup');setShippingText('0');}}/> Retirada</label><label><input type="radio" name="slim-fulfillment" aria-label="Entrega no endereço" checked={fulfillmentMode==='delivery'} onChange={()=>setFulfillmentMode('delivery')}/> Entrega no endereço</label></div>
     {fulfillmentMode==='pickup'?<p className="text-sm text-muted-foreground">Retirada sem cobrança de frete.</p>:<>
      <div className="grid gap-3 sm:grid-cols-2">
       <label className="text-sm">Destinatário<input aria-label="Destinatário" className={field} value={delivery.recipient} onChange={e=>setDelivery(v=>({...v,recipient:e.target.value}))} maxLength={160} required/></label>
       <label className="text-sm">Telefone para entrega<input aria-label="Telefone para entrega" type="tel" className={field} value={delivery.phone} onChange={e=>setDelivery(v=>({...v,phone:e.target.value}))} maxLength={40} required/></label>
       <label className="text-sm">CEP<input aria-label="CEP de entrega" inputMode="numeric" placeholder="00000-000" className={field} value={delivery.postalCode} onChange={e=>setDelivery(v=>({...v,postalCode:e.target.value}))} maxLength={9} required/></label>
       <label className="text-sm">Logradouro<input aria-label="Logradouro de entrega" className={field} value={delivery.street} onChange={e=>setDelivery(v=>({...v,street:e.target.value}))} maxLength={200} required/></label>
       <label className="text-sm">Número<input aria-label="Número de entrega" className={field} value={delivery.number} onChange={e=>setDelivery(v=>({...v,number:e.target.value}))} maxLength={30} placeholder="Número ou s/n" required/></label>
       <label className="text-sm">Complemento (opcional)<input aria-label="Complemento de entrega" className={field} value={delivery.complement} onChange={e=>setDelivery(v=>({...v,complement:e.target.value}))} maxLength={120}/></label>
       <label className="text-sm">Bairro<input aria-label="Bairro de entrega" className={field} value={delivery.neighborhood} onChange={e=>setDelivery(v=>({...v,neighborhood:e.target.value}))} maxLength={100} required/></label>
       <label className="text-sm">Cidade<input aria-label="Cidade de entrega" className={field} value={delivery.city} onChange={e=>setDelivery(v=>({...v,city:e.target.value}))} maxLength={100} required/></label>
       <label className="text-sm">UF<input aria-label="UF de entrega" className={field} value={delivery.state} onChange={e=>setDelivery(v=>({...v,state:e.target.value.toUpperCase()}))} maxLength={2} placeholder="SP" required/></label>
       <label className="text-sm">Frete (R$)<input aria-label="Frete em reais" inputMode="decimal" className={field} value={shippingText} onChange={e=>setShippingText(e.target.value)} maxLength={20} required/></label>
       <label className="text-sm sm:col-span-2">Observações de entrega (opcional)<textarea aria-label="Observações de entrega" className={field} value={delivery.notes} onChange={e=>setDelivery(v=>({...v,notes:e.target.value}))} maxLength={500} rows={2}/></label>
      </div><p className="text-xs text-muted-foreground">Informe o frete combinado com o cliente. Use 0 para entrega grátis. Este endereço fica registrado no pedido.</p>
     </>}
    </section>
    <section className="rounded-xl border bg-card p-5 space-y-3"><h2 className="font-semibold">Pagamento e desconto</h2><div className="grid gap-3 sm:grid-cols-2">
     <label className="text-sm">Forma<select className={field} value={method} onChange={e=>{setMethod(e.target.value as typeof method);setInstallments(1);}}>{methods.map(([value,label])=><option key={value} value={value}>{label}</option>)}</select></label>
     <label className="text-sm">Situação<select className={field} value={paymentStatus} onChange={e=>setPaymentStatus(e.target.value as typeof paymentStatus)}><option value="pending">Pagamento pendente</option><option value="paid">Recebimento informado pelo operador</option></select></label>
     {method==='credit_card'&&<label className="text-sm">Parcelas<input type="number" min="1" max="24" step="1" className={field} value={installments} onChange={e=>setInstallments(Number(e.target.value))}/></label>}
     <label className="text-sm">Desconto<select className={field} value={discountKind} onChange={e=>{setDiscountKind(e.target.value as typeof discountKind);setDiscountText('0');}}><option value="amount">Valor em reais</option><option value="percent">Percentual</option></select></label>
     <label className="text-sm">{discountKind==='amount'?'Valor do desconto (R$)':'Percentual (%)'}<input inputMode="decimal" className={field} value={discountText} onChange={e=>setDiscountText(e.target.value)}/></label>
    </div><p className="text-xs text-muted-foreground">O desconto se aplica somente aos produtos. Selecionar PIX, cartão ou boleto não executa uma cobrança nem confirma um pagamento bancário.</p><label className="block text-sm">Observações<textarea className={field} value={notes} onChange={e=>setNotes(e.target.value)} maxLength={2000} rows={3}/></label></section>
   </fieldset>
   <aside className="self-start rounded-xl border bg-card p-5 space-y-4 xl:sticky xl:top-5"><h2 className="font-semibold">Resumo e confirmação</h2>
    {preview?<><dl className="space-y-3 text-sm"><div className="flex justify-between"><dt>Subtotal dos produtos</dt><dd>{formatCheckoutCents(preview.subtotalCents)}</dd></div><div className="flex justify-between"><dt>Desconto nos produtos</dt><dd>{formatCheckoutCents(preview.discountCents)}</dd></div><div className="flex justify-between"><dt>Frete</dt><dd>{formatCheckoutCents(preview.shippingCents??0)}</dd></div><div className="flex justify-between border-t pt-3 text-lg font-semibold"><dt>Total</dt><dd>{formatCheckoutCents(preview.totalCents)}</dd></div></dl>
     {preview.fulfillment&&<section aria-label="Entrega revisada" className="border-t pt-3 text-sm space-y-1"><h3 className="font-medium">{preview.fulfillment.mode==='pickup'?'Retirada':'Entrega no endereço'}</h3>{preview.fulfillment.mode==='delivery'&&<><p>{preview.fulfillment.recipient} · {preview.fulfillment.phone}</p><address className="not-italic break-words">{preview.fulfillment.street}, {preview.fulfillment.number}{preview.fulfillment.complement?` · ${preview.fulfillment.complement}`:''}<br/>{preview.fulfillment.neighborhood} · {preview.fulfillment.city}/{preview.fulfillment.state}<br/>CEP {preview.fulfillment.postalCode}</address>{preview.fulfillment.notes&&<p>Observações de entrega: {preview.fulfillment.notes}</p>}</>}</section>}
    </>:<p className="text-sm text-muted-foreground">Preencha os campos para calcular o total. Valores inválidos não serão tratados como zero.</p>}
    {error&&<p role="alert" className="text-sm text-destructive">{error}</p>}{state?.error&&<p role="alert" className="text-sm text-destructive">{state.error}</p>}{notice&&<p role="status" className="text-sm">{notice}</p>}
    {state?.receipt?<div role="status" className="rounded-md border border-emerald-500/40 p-3"><strong>Pedido {state.receipt.number} confirmado</strong><p className="mt-1 text-xs break-all">{state.receipt.orderId}</p></div>:state?.state==='uncertain'?<><p className="break-all text-xs">Referência da tentativa: {state.requestId}</p><button type="button" className="w-full rounded-md border p-3 text-sm" disabled={busy||scopeChanged} onClick={()=>void apply('reconcile')}>{busy?'Consultando...':'Consultar resultado sem reenviar'}</button></>:state?.state==='review'?<><p className="text-sm">Confira o cliente, os itens e o valor. A confirmação deve registrar a venda e movimentar o estoque uma única vez.</p><button type="button" className="w-full rounded-md bg-primary p-3 text-sm font-semibold text-primary-foreground" disabled={busy||!transport||scopeChanged} onClick={()=>void apply('approve')}>Confirmar pedido</button><button type="button" className="w-full rounded-md border p-2 text-sm" disabled={busy} onClick={()=>setSession(null)}>Voltar e corrigir</button></>:state?.state==='submitting'?<p role="status">Aguardando confirmação da gravação...</p>:<button type="button" className="w-full rounded-md bg-primary p-3 text-sm font-semibold text-primary-foreground disabled:opacity-50" disabled={loading||Boolean(loadError)||!transport||scopeChanged} onClick={review}>Revisar pedido</button>}
    <p className="text-xs text-muted-foreground">O documento comercial não substitui uma nota fiscal autorizada. Nenhum envio ao WhatsApp é automático.</p>
   </aside>
  </div>
 </div>;
}
