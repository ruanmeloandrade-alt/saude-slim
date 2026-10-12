-- 1) search_path fixo
ALTER FUNCTION public.move_to_dlq(text, text, bigint, jsonb) SET search_path = public, pgmq;
ALTER FUNCTION public.enqueue_email(text, jsonb) SET search_path = public, pgmq;
ALTER FUNCTION public.delete_email(text, bigint) SET search_path = public, pgmq;
ALTER FUNCTION public.read_email_batch(text, integer, integer) SET search_path = public, pgmq;
ALTER FUNCTION public.touch_updated_at() SET search_path = public;
ALTER FUNCTION public.is_valid_cpf(text) SET search_path = public;
ALTER FUNCTION public.isnumeric_or_empty(text) SET search_path = public;

-- 2) Funções exclusivas do servidor: sem execução por anon/authenticated
REVOKE EXECUTE ON FUNCTION public.get_evolution_credentials_service(uuid, text) FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.get_integration_secret_service(uuid, text, text) FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.set_integration_secret_service(uuid, text, jsonb, text, jsonb, text) FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.get_evolution_session_by_secret(text, text) FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.get_zapi_session_by_secret(text, text) FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.get_meta_page_token(text, text) FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.get_meta_page_token(uuid, text, text) FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.refresh_meta_integration_token(uuid, jsonb, text, timestamptz) FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.mark_integration_needs_reconnect(uuid, text, text) FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.email_queue_dispatch() FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.email_queue_wake() FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.enqueue_email(text, jsonb) FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.delete_email(text, bigint) FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.read_email_batch(text, integer, integer) FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.move_to_dlq(text, text, bigint, jsonb) FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.purge_old_conversation_files() FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.purge_old_raw_payloads() FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.purge_old_user_sessions() FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.expire_trials_and_subs() FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.generate_workspace_slug(text) FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.create_default_crm_source() FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.create_default_subscription() FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.crm_forms_touch_updated_at() FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.touch_updated_at() FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.update_updated_at_column() FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.workflow_time_session_close() FROM anon, authenticated, public;

-- 3) Funções com checagem interna de auth.uid(): bloqueadas apenas para visitantes
REVOKE EXECUTE ON FUNCTION public.get_integration_secret(uuid, text, text) FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.set_integration_secret(uuid, text, jsonb, text, jsonb, text) FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.get_evolution_credentials(uuid, text) FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.set_evolution_credentials(uuid, text, text, text) FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.set_evolution_credentials(uuid, text, text, text, text) FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.get_zapi_credentials(uuid, text) FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.set_zapi_credentials(uuid, text, text, text, text) FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.accept_invitation(uuid) FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.get_workspace_default_currency(uuid) FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.set_workspace_default_currency(uuid, text) FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.has_role(uuid, app_role) FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.is_workspace_member(uuid, uuid) FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.can_admin_workspace(uuid, uuid) FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.can_manage_workflow(uuid, uuid) FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.can_view_workflow_pipeline(uuid, uuid) FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.workspace_has_module(uuid, text) FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.workspace_seat_limit(uuid) FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.whatsapp_number_limit(uuid) FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.count_active_whatsapp_sessions(uuid) FROM anon, public;

-- 4) Storage: bucket employee-of-month escopado por workspace
DROP POLICY IF EXISTS employee_of_month_select_members ON storage.objects;
CREATE POLICY employee_of_month_select_members
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'employee-of-month'
    AND (storage.foldername(name))[1] ~ '^[0-9a-fA-F-]{36}$'
    AND public.is_workspace_member(((storage.foldername(name))[1])::uuid, auth.uid())
  );

DROP POLICY IF EXISTS employee_of_month_upload_managers ON storage.objects;
CREATE POLICY employee_of_month_upload_managers
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'employee-of-month'
    AND (storage.foldername(name))[1] ~ '^[0-9a-fA-F-]{36}$'
    AND public.can_manage_workflow(((storage.foldername(name))[1])::uuid, auth.uid())
  );

DROP POLICY IF EXISTS employee_of_month_delete_managers ON storage.objects;
CREATE POLICY employee_of_month_delete_managers
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'employee-of-month'
    AND (storage.foldername(name))[1] ~ '^[0-9a-fA-F-]{36}$'
    AND public.can_manage_workflow(((storage.foldername(name))[1])::uuid, auth.uid())
  );

-- 5) whatsapp_web_messages: leitura só para membros autenticados (inclui realtime)
REVOKE ALL ON public.whatsapp_web_messages FROM anon;
DROP POLICY IF EXISTS "members read messages" ON public.whatsapp_web_messages;
CREATE POLICY "members read messages"
  ON public.whatsapp_web_messages FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()));

-- 6) whatsapp_web_session_auth: fail-closed explícito
ALTER TABLE public.whatsapp_web_session_auth ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.whatsapp_web_session_auth FROM anon, authenticated;
GRANT ALL ON public.whatsapp_web_session_auth TO service_role;
COMMENT ON TABLE public.whatsapp_web_session_auth IS 'Credenciais de sessão WhatsApp. Sem políticas RLS e sem grants para anon/authenticated: acesso exclusivo do servidor (service_role).';