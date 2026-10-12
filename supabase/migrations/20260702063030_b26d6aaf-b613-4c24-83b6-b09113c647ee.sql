CREATE OR REPLACE FUNCTION public.count_active_whatsapp_sessions(_workspace_id uuid)
RETURNS integer
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $function$
  SELECT COUNT(*)::int
  FROM public.whatsapp_web_sessions
  WHERE workspace_id = _workspace_id
    AND status IN ('aguardando_qr', 'conectando', 'conectado')
    AND COALESCE(metadata->>'deleted', 'false') <> 'true';
$function$;