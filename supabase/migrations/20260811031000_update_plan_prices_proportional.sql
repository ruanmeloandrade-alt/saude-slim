-- Reposicionamento comercial dos planos MKTOn em 2026-08-10.
-- Cada ciclo preserva a proporção da tabela histórica imediatamente anterior.
-- Fórmula: novo_periodo = round(preco_periodo_anterior * novo_mensal / mensal_anterior).

with new_prices(plan_code, period, amount_cents) as (
  values
    ('starter',      '1m',  19700),
    ('starter',      '3m',  49126),
    ('starter',      '6m',  98500),
    ('starter',      '1y', 177300),

    ('professional', '1m',  39800),
    ('professional', '3m',  99357),
    ('professional', '6m', 199000),
    ('professional', '1y', 358200),

    ('business',     '1m',  78200),
    ('business',     '3m', 195304),
    ('business',     '6m', 391000),
    ('business',     '1y', 703800),

    ('enterprise',   '1m', 129300),
    ('enterprise',   '3m', 323034),
    ('enterprise',   '6m', 646500),
    ('enterprise',   '1y',1163700)
)
update public.plan_prices pp
set amount_cents = np.amount_cents
from public.plans p
join new_prices np on np.plan_code = p.code
where pp.plan_id = p.id
  and pp.period = np.period;

comment on table public.plan_prices is
  'Preços canônicos dos planos MKTOn; ciclos 3m/6m/1y preservam a proporção comercial da tabela histórica de 2026-07-30.';
