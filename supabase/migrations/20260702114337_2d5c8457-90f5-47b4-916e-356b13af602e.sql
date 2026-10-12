CREATE OR REPLACE FUNCTION public.count_active_whatsapp_sessions(_workspace_id uuid)
RETURNS int
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT COUNT(*)::int
    FROM public.whatsapp_web_sessions
   WHERE workspace_id = _workspace_id
     AND provider = 'evolution'
     AND status = 'conectado'
     AND COALESCE((metadata->>'deleted')::boolean, false) = false;
$$;