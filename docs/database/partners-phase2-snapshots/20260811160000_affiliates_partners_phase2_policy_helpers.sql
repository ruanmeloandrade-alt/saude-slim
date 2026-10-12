-- MktOn Partners / Afiliados — correção de execução dos helpers usados por RLS.
-- Os helpers continuam sem acesso anon/public, mas authenticated precisa EXECUTE
-- porque as policies os invocam durante SELECT/UPDATE do próprio usuário.

revoke all on function public.partner_program_is_admin(uuid) from public, anon;
revoke all on function public.partner_program_is_email_confirmed(uuid) from public, anon;

grant execute on function public.partner_program_is_admin(uuid) to authenticated, service_role;
grant execute on function public.partner_program_is_email_confirmed(uuid) to authenticated, service_role;

-- Helpers de mutação/auditoria permanecem internos.
revoke all on function public.partner_program_write_audit(uuid,text,text,text,text,jsonb,jsonb)
  from public, anon, authenticated;
grant execute on function public.partner_program_write_audit(uuid,text,text,text,text,jsonb,jsonb)
  to service_role;
