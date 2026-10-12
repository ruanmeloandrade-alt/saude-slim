-- Elev8: apenas layout visual do Router Atendimento Inicial.
-- Mantém toda a lógica; distribui as saídas ao redor da condição central.

update public.salesbot_blocks sb
set position_x = case sb.local_id
  when 'check-origin' then 4000
  when 'route-social' then 1800
  when 'route-trafego' then 3000
  when 'route-mkton' then 4400
  when 'route-start' then 5800
  when 'route-growth' then 6400
  when 'route-funil' then 5400
  when 'route-geral' then 2600
  when 'end' then 4000
  else sb.position_x
end,
position_y = case sb.local_id
  when 'check-origin' then 2800
  when 'route-social' then 1200
  when 'route-trafego' then 700
  when 'route-mkton' then 700
  when 'route-start' then 1200
  when 'route-growth' then 2800
  when 'route-funil' then 4300
  when 'route-geral' then 4300
  when 'end' then 5400
  else sb.position_y
end,
updated_at=now()
from public.salesbots b
where b.id=sb.salesbot_id
  and b.workspace_id='3c7d5f53-9141-445a-8d58-ca41d24eb572'::uuid
  and b.local_id='elav8-router-initial';
