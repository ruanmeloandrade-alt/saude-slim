CREATE TABLE public.slim_inbox_favorites(
 workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
 user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE DEFAULT auth.uid(),
 kind text NOT NULL CHECK(kind IN ('bot','agent','lead','group','sticker')),
 target_id text NOT NULL CHECK(length(target_id) BETWEEN 1 AND 200),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(workspace_id,user_id,kind,target_id)
);
ALTER TABLE public.slim_inbox_favorites ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.slim_inbox_favorites FROM PUBLIC,anon;
GRANT SELECT,INSERT,DELETE ON public.slim_inbox_favorites TO authenticated;
CREATE POLICY own_inbox_favorites ON public.slim_inbox_favorites FOR ALL TO authenticated
 USING(user_id=(SELECT auth.uid()) AND private.slim_workspace_access(workspace_id))
 WITH CHECK(user_id=(SELECT auth.uid()) AND private.slim_workspace_access(workspace_id));
CREATE POLICY slim_session_security_required ON public.slim_inbox_favorites AS RESTRICTIVE FOR ALL TO authenticated
 USING((SELECT private.slim_session_security_allowed())) WITH CHECK((SELECT private.slim_session_security_allowed()));

CREATE INDEX IF NOT EXISTS slim_latest_inbound_activity ON public.lead_activities(workspace_id,lead_id,occurred_at DESC,id DESC) WHERE type='message_in';
CREATE OR REPLACE FUNCTION public.slim_latest_lead_inbound(_workspace_id uuid,_lead_ids uuid[])
RETURNS TABLE(lead_id uuid,preview text,message_at timestamptz) LANGUAGE sql STABLE SECURITY INVOKER SET search_path='' AS $preview$
 SELECT l.id,left(CASE WHEN a.payload->>'deleted_for_all'='true' THEN 'Mensagem apagada'
  ELSE coalesce(nullif(a.payload->>'text',''),CASE a.payload->>'media_type' WHEN 'audio' THEN 'Áudio enviado pelo lead' WHEN 'image' THEN 'Imagem enviada pelo lead' WHEN 'video' THEN 'Vídeo enviado pelo lead' WHEN 'sticker' THEN 'Figurinha enviada pelo lead' WHEN 'document' THEN coalesce(a.payload->>'file_name','Arquivo enviado pelo lead') ELSE 'Mensagem recebida' END) END,500),a.occurred_at
 FROM public.leads l JOIN LATERAL(SELECT payload,occurred_at FROM public.lead_activities
  WHERE workspace_id=_workspace_id AND lead_id=l.id AND type='message_in' ORDER BY occurred_at DESC,id DESC LIMIT 1)a ON true
 WHERE l.workspace_id=_workspace_id AND l.id=ANY(_lead_ids) AND cardinality(_lead_ids)<=5000;
$preview$;
REVOKE ALL ON FUNCTION public.slim_latest_lead_inbound(uuid,uuid[]) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.slim_latest_lead_inbound(uuid,uuid[]) TO authenticated;
