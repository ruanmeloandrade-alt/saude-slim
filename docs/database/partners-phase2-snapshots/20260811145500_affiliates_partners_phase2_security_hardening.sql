-- MktOn Partners / Afiliados — Fase 2, hardening do Bloco A
-- Remove qualquer confiança em raw_user_meta_data para autorização e reduz
-- a superfície pública de SECURITY DEFINER / tabelas do programa.

-- O cadastro do programa é provisionado exclusivamente pelo endpoint server-side
-- após inviteUserByEmail. Não confiar em metadata fornecido pelo cliente.
drop trigger if exists trg_partner_program_bootstrap_auth_user on auth.users;

-- Helpers internos não são endpoints públicos.
revoke all on function public.partner_program_is_admin(uuid) from public, anon, authenticated;
revoke all on function public.partner_program_is_email_confirmed(uuid) from public, anon, authenticated;
revoke all on function public.partner_program_normalize_referral_code(text) from public, anon, authenticated;
revoke all on function public.partner_program_build_referral_code(uuid, text) from public, anon, authenticated;
revoke all on function public.partner_program_write_audit(uuid,text,text,text,text,jsonb,jsonb) from public, anon, authenticated;
revoke all on function public.partner_program_audit_email_confirmation() from public, anon, authenticated;

-- Remove completamente a função que confiava em raw_user_meta_data. DROP IF EXISTS
-- é intencional: ambientes que já receberam parte do hardening não quebram aqui.
drop function if exists public.partner_program_bootstrap_auth_user();

-- RPCs intencionalmente expostos a usuários autenticados.
revoke all on function public.partner_program_request_role(text) from public, anon;
grant execute on function public.partner_program_request_role(text) to authenticated, service_role;

revoke all on function public.partner_program_my_identity() from public, anon;
grant execute on function public.partner_program_my_identity() to authenticated, service_role;

revoke all on function public.partner_program_set_role_status(uuid,text,text,text) from public, anon;
grant execute on function public.partner_program_set_role_status(uuid,text,text,text) to authenticated, service_role;

-- Service role precisa dos helpers para provisionamento/admin server-side.
grant execute on function public.partner_program_is_admin(uuid) to service_role;
grant execute on function public.partner_program_is_email_confirmed(uuid) to service_role;
grant execute on function public.partner_program_normalize_referral_code(text) to service_role;
grant execute on function public.partner_program_build_referral_code(uuid, text) to service_role;
grant execute on function public.partner_program_write_audit(uuid,text,text,text,text,jsonb,jsonb) to service_role;

-- Objetos de dados: negar anon e conceder somente o mínimo para authenticated.
revoke all on table public.partner_program_profiles from anon;
revoke all on table public.partner_program_roles from anon;
revoke all on table public.partner_program_partner_profiles from anon;
revoke all on table public.partner_program_audit_log from anon;

revoke all on table public.partner_program_profiles from authenticated;
revoke all on table public.partner_program_roles from authenticated;
revoke all on table public.partner_program_partner_profiles from authenticated;
revoke all on table public.partner_program_audit_log from authenticated;

grant select on table public.partner_program_profiles to authenticated;
grant update (display_name, whatsapp, acquisition_channel, audience_description)
  on table public.partner_program_profiles to authenticated;

grant select on table public.partner_program_roles to authenticated;

grant select on table public.partner_program_partner_profiles to authenticated;
grant update (professional_bio, specialties)
  on table public.partner_program_partner_profiles to authenticated;

grant select on table public.partner_program_audit_log to authenticated;

grant all on table public.partner_program_profiles to service_role;
grant all on table public.partner_program_roles to service_role;
grant all on table public.partner_program_partner_profiles to service_role;
grant all on table public.partner_program_audit_log to service_role;

-- Mantém RLS como segunda camada mesmo com grants mínimos.
alter table public.partner_program_profiles force row level security;
alter table public.partner_program_roles force row level security;
alter table public.partner_program_partner_profiles force row level security;
alter table public.partner_program_audit_log force row level security;

-- O próprio usuário só enxerga dados do programa após e-mail confirmado.
-- Admin continua vendo tudo pelas policies do arquivo foundation.

-- Validação estrutural explícita para impedir migração parcial silenciosa.
do $$
begin
  if to_regclass('public.partner_program_profiles') is null
     or to_regclass('public.partner_program_roles') is null
     or to_regclass('public.partner_program_partner_profiles') is null
     or to_regclass('public.partner_program_audit_log') is null then
    raise exception 'PARTNER_PROGRAM_FOUNDATION_MISSING';
  end if;
end
$$;
