-- Accepted by Supabase.apply_migration as slim_checkout_interrupted_attempt_closure on 2026-10-16.
-- Audit copy only. Not loaded by prebuild or an automatic migration runner.
-- The subsequent metadata lookup for its version was refused; no timestamp was fabricated.
-- Scope: an operator can abandon an interrupted checkout attempt, never an existing order.
-- No order, stock, customer, credential or message is modified by this migration.
CREATE TABLE public.slim_checkout_attempt_closures (
 workspace_id uuid NOT NULL REFERENCES public.workspaces(id),
 request_id uuid NOT NULL,
 actor_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id),
 closed_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY (workspace_id,request_id)
);
ALTER TABLE public.slim_checkout_attempt_closures ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.slim_checkout_attempt_closures FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT ON public.slim_checkout_attempt_closures TO authenticated;
GRANT SELECT ON public.slim_checkout_attempt_closures TO service_role;
CREATE POLICY slim_attempt_closure_read ON public.slim_checkout_attempt_closures FOR SELECT TO authenticated
 USING (actor_id=(SELECT auth.uid()) AND private.slim_workspace_access(workspace_id));
CREATE POLICY slim_attempt_closure_insert ON public.slim_checkout_attempt_closures FOR INSERT TO authenticated
 WITH CHECK (actor_id=(SELECT auth.uid()) AND private.slim_workspace_access(workspace_id,'operator'));
CREATE FUNCTION private.slim_guard_checkout_close() RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path='' AS $fn$
BEGIN
 IF auth.uid() IS NULL OR NEW.actor_id IS DISTINCT FROM auth.uid() OR NOT private.slim_workspace_access(NEW.workspace_id,'operator') THEN
  RAISE EXCEPTION 'Sem permissão para encerrar esta tentativa.' USING ERRCODE='42501';
 END IF;
 IF current_setting('transaction_isolation')<>'read committed' THEN
  RAISE EXCEPTION 'A recuperação exige uma leitura atual da transação.' USING ERRCODE='22023';
 END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended(NEW.workspace_id::text||NEW.request_id::text,0));
 IF EXISTS(SELECT 1 FROM public.slim_orders o WHERE o.workspace_id=NEW.workspace_id AND o.request_id=NEW.request_id) THEN
  RAISE EXCEPTION 'Esta tentativa já possui um pedido. Consulte o histórico.' USING ERRCODE='22023';
 END IF;
 NEW.closed_at:=clock_timestamp();
 RETURN NEW;
END;$fn$;
REVOKE ALL ON FUNCTION private.slim_guard_checkout_close() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.slim_guard_checkout_close() TO authenticated;
CREATE TRIGGER slim_guard_attempt_closure BEFORE INSERT ON public.slim_checkout_attempt_closures
 FOR EACH ROW EXECUTE FUNCTION private.slim_guard_checkout_close();
CREATE FUNCTION public.slim_close_checkout_attempt(_workspace_id uuid,_request_id uuid)
 RETURNS jsonb LANGUAGE plpgsql SECURITY INVOKER SET search_path='' AS $fn$
DECLARE existing public.slim_orders; closed public.slim_checkout_attempt_closures;
BEGIN
 IF auth.uid() IS NULL OR _request_id IS NULL OR NOT private.slim_workspace_access(_workspace_id,'operator') THEN
  RAISE EXCEPTION 'Sem permissão para encerrar a tentativa nesta empresa.' USING ERRCODE='42501';
 END IF;
 IF current_setting('transaction_isolation')<>'read committed' THEN
  RAISE EXCEPTION 'A recuperação exige uma leitura atual da transação.' USING ERRCODE='22023';
 END IF;
 IF NOT pg_try_advisory_xact_lock(hashtextextended(_workspace_id::text||_request_id::text,0)) THEN
  RETURN jsonb_build_object('state','processing','workspaceId',_workspace_id,'requestId',_request_id);
 END IF;
 SELECT * INTO existing FROM public.slim_orders o WHERE o.workspace_id=_workspace_id AND o.request_id=_request_id;
 IF FOUND THEN
  IF existing.created_by IS DISTINCT FROM auth.uid() THEN
   RAISE EXCEPTION 'Referência pertence a outro operador.' USING ERRCODE='42501';
  END IF;
  RETURN jsonb_build_object('state','existing','workspaceId',_workspace_id,'requestId',_request_id,'orderId',existing.id);
 END IF;
 INSERT INTO public.slim_checkout_attempt_closures(workspace_id,request_id,actor_id)
  VALUES(_workspace_id,_request_id,auth.uid()) ON CONFLICT(workspace_id,request_id) DO NOTHING;
 SELECT * INTO closed FROM public.slim_checkout_attempt_closures c WHERE c.workspace_id=_workspace_id AND c.request_id=_request_id AND c.actor_id=auth.uid();
 IF NOT FOUND THEN RAISE EXCEPTION 'Referência não disponível para este operador.' USING ERRCODE='42501';END IF;
 RETURN jsonb_build_object('state','closed','workspaceId',_workspace_id,'requestId',_request_id,'actorId',closed.actor_id);
END;$fn$;
REVOKE ALL ON FUNCTION public.slim_close_checkout_attempt(uuid,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.slim_close_checkout_attempt(uuid,uuid) TO authenticated;
DO $migration$
DECLARE definition text; anchor text:= ' PERFORM pg_advisory_xact_lock(hashtextextended(_workspace_id::text||_request_id::text,0));'; guard text;
BEGIN
 definition:=pg_get_functiondef('private.slim_confirm_order(uuid,uuid,jsonb)'::regprocedure);
 IF array_length(string_to_array(definition,anchor),1)<>2 THEN RAISE EXCEPTION 'Contrato de confirmação mudou; nenhuma edição aplicada.';END IF;
 IF position('slim_checkout_attempt_closures' in definition)>0 THEN RAISE EXCEPTION 'Barreira de tentativa já instalada; revisar migration.';END IF;
 guard:=anchor||E'\n IF EXISTS(SELECT 1 FROM public.slim_checkout_attempt_closures c WHERE c.workspace_id=_workspace_id AND c.request_id=_request_id) THEN\n  RAISE EXCEPTION ''Tentativa encerrada sem pedido. Revise os itens e inicie uma nova confirmação.'' USING ERRCODE=''22023'';\n END IF;';
 EXECUTE replace(definition,anchor,guard);
END;$migration$;
COMMENT ON TABLE public.slim_checkout_attempt_closures IS 'Immutable abandoned-checkout references; shares the confirm-order lock and prevents late confirmations. Not cancellation of an order.';
NOTIFY pgrst,'reload schema';
