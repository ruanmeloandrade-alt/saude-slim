import { useMemo, useState } from 'react';
import { buildOrderReadModel, formatOrderCents, type OrderFilters, type OrderSnapshot } from '../../lib/slim-order-read.core';
type Props = {
  workspaceId: string; response: unknown; loading: boolean; error?: string;
  onDocument: (order: OrderSnapshot) => void | Promise<void>;
  onCancel?: (order: OrderSnapshot) => void | Promise<void>; cancelBusy?: string | null;
};
export function SlimOrderHistory({ workspaceId, response, loading, error, onDocument, onCancel, cancelBusy }: Props) {
  const [query, setQuery] = useState('');
  const [status, setStatus] = useState<NonNullable<OrderFilters['status']>>('all');
  const [from, setFrom] = useState('');
  const [to, setTo] = useState('');
  const [page, setPage] = useState(1);
  const [documentBusy, setDocumentBusy] = useState<string | null>(null);
  const [documentError, setDocumentError] = useState('');
  const result = useMemo(() => {
    if (loading || error) return { model: null, error: '' };
    try { return { model: buildOrderReadModel(response, workspaceId, { query, status, from, to }), error: '' }; }
    catch (e) { return { model: null, error: e instanceof Error ? e.message : 'Não foi possível conferir o histórico.' }; }
  }, [loading, error, response, workspaceId, query, status, from, to]);
  async function openDocument(order: OrderSnapshot) {
    if (documentBusy) return;
    setDocumentBusy(order.orderId); setDocumentError('');
    try { await onDocument(structuredClone(order)); }
    catch { setDocumentError('O documento não pôde ser aberto. O pedido continua registrado; não finalize outra venda.'); }
    finally { setDocumentBusy(null); }
  }
  const model = result.model;
  const pages = model ? Math.max(1, Math.ceil(model.rows.length / 20)) : 1;
  const safePage = Math.min(page, pages);
  const fields = 'rounded-md border border-input bg-background p-2 text-sm';
  return <section className="space-y-4" aria-busy={loading}>
    <header><h2 className="text-xl font-semibold">Histórico de pedidos</h2><p className="text-sm text-muted-foreground">Valores da venda confirmada, sem reconsultar o preço atual do catálogo. Datas no horário de Brasília.</p></header>
    <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
      <label className="grid gap-1 text-sm">Buscar cliente, pedido ou produto<input className={fields} value={query} onChange={e => { setQuery(e.target.value); setPage(1); }} /></label>
      <label className="grid gap-1 text-sm">Situação<select className={fields} value={status} onChange={e => { setStatus(e.target.value as typeof status); setPage(1); }}><option value="all">Todos</option><option value="confirmed">Confirmados</option><option value="cancelled">Cancelados</option></select></label>
      <label className="grid gap-1 text-sm">De<input className={fields} type="date" value={from} onChange={e => { setFrom(e.target.value); setPage(1); }} /></label>
      <label className="grid gap-1 text-sm">Até<input className={fields} type="date" value={to} onChange={e => { setTo(e.target.value); setPage(1); }} /></label>
    </div>
    {loading ? <p role="status">Carregando os pedidos registrados...</p> : error || result.error ? <p role="alert" className="rounded-md border border-destructive/30 p-4 text-sm text-destructive">{error || result.error}</p> : model && <>
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        <Metric label="Pedidos confirmados no filtro" value={String(model.totals.confirmedCount)} />
        <Metric label="Valor dos pedidos confirmados" value={formatOrderCents(model.totals.totalCents)} />
        <Metric label="Recebimento informado" value={formatOrderCents(model.totals.receivedDeclaredCents)} />
        <Metric label="Pagamento pendente" value={formatOrderCents(model.totals.pendingPaymentCents)} />
      </div>
      <p className="text-xs text-muted-foreground">Recebimento informado pelo operador não é confirmação bancária. Cancelados: {model.totals.cancelledCount}, fora dos totais de vendas. Baixas e estornos são registrados por pedido no servidor.</p>
      {documentError && <p role="alert" className="text-sm text-destructive">{documentError}</p>}
      <div className="divide-y rounded-xl border border-border">
        {!model.rows.length ? <p className="p-6 text-sm text-muted-foreground">Nenhum pedido corresponde aos filtros.</p> : model.rows.slice((safePage - 1) * 20, safePage * 20).map(order => <article key={order.orderId} className="space-y-3 p-4">
          <div className="flex flex-wrap justify-between gap-3"><div><h3 className="font-semibold">{order.number} · {order.customer.name}</h3><p className="text-xs text-muted-foreground">{new Intl.DateTimeFormat('pt-BR', { timeZone: 'America/Sao_Paulo', dateStyle: 'short', timeStyle: 'short' }).format(new Date(order.confirmedAt))} · {order.status === 'cancelled' ? 'Cancelado' : 'Confirmado'}</p></div><strong className="tabular-nums">{formatOrderCents(order.totalCents)}</strong></div>
          <ul className="space-y-1 text-sm">{order.items.map(item => <li key={item.productId}>{item.quantity} × {item.name} · {formatOrderCents(item.unitPriceCents)} por unidade · Total: {formatOrderCents(item.totalCents)}</li>)}</ul>
          {order.status === 'cancelled' && <p className="text-sm">Motivo: {order.cancellationReason}</p>}
          <p className="text-xs text-muted-foreground">Subtotal {formatOrderCents(order.subtotalCents)} · Desconto {formatOrderCents(order.discountCents)} · {order.payment.status === 'paid' ? 'Recebimento informado' : 'Pagamento pendente'}</p>
          <button type="button" className="rounded-md border border-border px-3 py-2 text-sm disabled:opacity-50" disabled={Boolean(documentBusy)} onClick={() => void openDocument(order)}>{documentBusy === order.orderId ? 'Abrindo...' : 'Documento do pedido'}</button>
          {order.status === 'confirmed' && onCancel && <button type="button" disabled={Boolean(cancelBusy)} onClick={() => void onCancel(order)} className="ml-3 rounded-md border border-destructive/40 px-3 py-2 text-sm text-destructive disabled:opacity-40">{cancelBusy === order.orderId ? 'Cancelando...' : 'Cancelar e estornar estoque'}</button>}
        </article>)}
      </div>
      <div className="flex items-center justify-between gap-3 text-sm"><span>{model.filteredRecords} registros · Página {safePage} de {pages}</span><div className="flex gap-2"><button type="button" className={fields} disabled={safePage <= 1} onClick={() => setPage(safePage - 1)}>Anterior</button><button type="button" className={fields} disabled={safePage >= pages} onClick={() => setPage(safePage + 1)}>Próxima</button></div></div>
    </>}
  </section>;
}
function Metric({ label, value }: { label: string; value: string }) { return <div className="rounded-lg border bg-card p-3"><p className="text-xs text-muted-foreground">{label}</p><p className="mt-1 text-lg font-semibold tabular-nums">{value}</p></div>; }
