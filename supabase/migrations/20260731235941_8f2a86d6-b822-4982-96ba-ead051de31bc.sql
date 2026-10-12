CREATE OR REPLACE FUNCTION public.list_workspace_users(_workspace_id uuid)
RETURNS TABLE(id uuid, name text, email text)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT m.user_id,
         COALESCE(NULLIF(p.display_name, ''), NULLIF(p.full_name, ''), NULLIF(u.email::text, ''), 'Usuário')::text,
         u.email::text
  FROM public.workspace_members m
  LEFT JOIN public.profiles p ON p.id = m.user_id
  LEFT JOIN auth.users u ON u.id = m.user_id
  WHERE m.workspace_id = _workspace_id
    AND (public.is_workspace_member(_workspace_id, auth.uid()) OR public.has_role(auth.uid(), 'super_admin'::app_role))
$$;

REVOKE ALL ON FUNCTION public.list_workspace_users(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.list_workspace_users(uuid) TO authenticated, service_role;