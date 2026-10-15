import { orderUuid, validateOrderSnapshot, validateOrderBatch, type OrderSnapshot } from './slim-order-read.core.ts';
import type { CheckoutQuote, ConfirmedCheckout } from './slim-checkout.core';
export type ErpDb = { from: (table: string) => any; rpc: (name: string, args: Record<string, unknown>) => PromiseLike<any> };
export const ORDER_COLUMNS = 'id,workspace_id,request_id,created_by,customer_id,status,subtotal_cents,discount_cents,total_cents,snapshot,confirmed_at,cancelled_at,cancellation_reason';
export function checked<T = any>(result: {data: T; error?: unknown}, message: string): T { if (result.error) throw new Error(message); return result.data; }
export async function erpRows(db: ErpDb, ws: string, table: string, columns: string) {
  orderUuid(ws, 'Empresa'); const out: any[] = [];
  for (;;) {
    const result = await db.from(table).select(columns).eq('workspace_id', ws).order('id').range(out.length, out.length + 499);
    const rows = checked(result, `Não foi possível consultar ${table}. Nenhum total parcial foi apresentado.`);
    if (!Array.isArray(rows)) throw new Error('Resposta de leitura inválida.');
    if (!rows.length) return out;
    out.push(...rows); if (out.length > 100000) throw new Error('Limite de leitura excedido. Refine o histórico.');
  }
}
export function persistedOrder(row: any, ws: string): OrderSnapshot {
  if (!row || row.workspace_id !== ws || row.id !== row.snapshot?.orderId || row.customer_id !== row.snapshot?.customer?.id || row.request_id !== row.snapshot?.requestId) throw new Error('Identificação do pedido inconsistente.');
  const result = validateOrderSnapshot({...row.snapshot, status: row.status, confirmedAt: row.confirmed_at, cancelledAt: row.cancelled_at, cancellationReason: row.cancellation_reason}, ws);
  if (result.totalCents !== Number(row.total_cents) || result.subtotalCents !== Number(row.subtotal_cents) || result.discountCents !== Number(row.discount_cents)) throw new Error('Total persistido não corresponde ao documento.');
  return result;
}
export async function loadErpOrder(db: ErpDb, ws: string, id: string) {
  orderUuid(id, 'Pedido'); const row = checked(await db.from('slim_orders').select(ORDER_COLUMNS).eq('workspace_id', ws).eq('id', id).maybeSingle(), 'Não foi possível consultar o pedido.');
  if (!row) throw new Error('Pedido não encontrado nesta empresa.');
  return {row, order: persistedOrder(row, ws)};
}
export async function loadErpOrders(db: ErpDb, ws: string) {
  const rows = await erpRows(db, ws, 'slim_orders', ORDER_COLUMNS);
  return validateOrderBatch({workspaceId: ws, complete: true, orders: rows.map(r => persistedOrder(r, ws))}, ws);
}
export function receiptFromOrder(order: OrderSnapshot): ConfirmedCheckout {
  if (order.status !== 'confirmed') throw new Error('Este pedido foi cancelado.');
  return {requestId:order.requestId,workspaceId:order.workspaceId,orderId:order.orderId,number:order.number,status:'confirmed',totalCents:order.totalCents};
}
export function quoteFromOrder(order: OrderSnapshot): CheckoutQuote {
  return {workspaceId:order.workspaceId,customer:{kind:'existing',id:order.customer.id},items:structuredClone(order.items),subtotalCents:order.subtotalCents,discountCents:order.discountCents,totalCents:order.totalCents,payment:order.payment as CheckoutQuote['payment'],notes:order.notes};
}
export async function lookupErpAttempt(db: ErpDb, ws: string, actor: string, request: string) {
  orderUuid(request,'Tentativa'); const row = checked(await db.from('slim_orders').select(ORDER_COLUMNS).eq('workspace_id',ws).eq('request_id',request).eq('created_by',actor).maybeSingle(),'Consulta da tentativa indisponível.');
  if (!row) return {state:'not_found' as const};
  const order=persistedOrder(row,ws);
  return order.status==='cancelled' ? {state:'rejected' as const,message:`Pedido ${order.number} já cancelado. Consulte o histórico.`} : {state:'confirmed' as const,receipt:receiptFromOrder(order)};
}
