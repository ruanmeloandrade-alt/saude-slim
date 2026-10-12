-- F06: a reserva atômica limpa reservas expiradas por expires_at sem filtrar
-- coupon_id. O índice composto anterior não atende bem esse DELETE global.

create index if not exists coupon_reservations_expires_at_idx
  on public.coupon_reservations (expires_at);
