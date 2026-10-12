
-- Adiciona campos de perfil
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS birth_date date,
  ADD COLUMN IF NOT EXISTS job_title text,
  ADD COLUMN IF NOT EXISTS internal_notes text,
  ADD COLUMN IF NOT EXISTS notification_prefs jsonb NOT NULL DEFAULT '{"email":true,"whatsapp":false,"platform":true,"commercial":true}'::jsonb;

-- Membros: tipo de papel + parceiro
ALTER TABLE public.workspace_members
  ADD COLUMN IF NOT EXISTS role_type text NOT NULL DEFAULT 'funcionario',
  ADD COLUMN IF NOT EXISTS is_partner boolean NOT NULL DEFAULT false;

-- Convites
CREATE TABLE IF NOT EXISTS public.workspace_invitations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  email text NOT NULL,
  role_type text NOT NULL DEFAULT 'funcionario',
  is_partner boolean NOT NULL DEFAULT false,
  token uuid NOT NULL UNIQUE DEFAULT gen_random_uuid(),
  invited_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  status text NOT NULL DEFAULT 'pending',
  modules text[] NOT NULL DEFAULT '{}',
  expires_at timestamptz NOT NULL DEFAULT (now() + interval '7 days'),
  accepted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS workspace_invitations_ws_idx ON public.workspace_invitations(workspace_id);
CREATE INDEX IF NOT EXISTS workspace_invitations_email_idx ON public.workspace_invitations(lower(email));

GRANT SELECT, INSERT, UPDATE, DELETE ON public.workspace_invitations TO authenticated;
GRANT ALL ON public.workspace_invitations TO service_role;

ALTER TABLE public.workspace_invitations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "owner manages invitations" ON public.workspace_invitations
  FOR ALL TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.workspaces w WHERE w.id = workspace_id AND w.owner_id = auth.uid())
    OR has_role(auth.uid(), 'super_admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.workspaces w WHERE w.id = workspace_id AND w.owner_id = auth.uid())
    OR has_role(auth.uid(), 'super_admin')
  );

CREATE POLICY "invited user views by email" ON public.workspace_invitations
  FOR SELECT TO authenticated
  USING (lower(email) = lower(coalesce((auth.jwt() ->> 'email'), '')));

CREATE TRIGGER touch_invitations BEFORE UPDATE ON public.workspace_invitations
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- Permissões de módulo por membro
CREATE TABLE IF NOT EXISTS public.module_permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  modules text[] NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(workspace_id, user_id)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.module_permissions TO authenticated;
GRANT ALL ON public.module_permissions TO service_role;

ALTER TABLE public.module_permissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "self read permissions" ON public.module_permissions
  FOR SELECT TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (SELECT 1 FROM public.workspaces w WHERE w.id = workspace_id AND w.owner_id = auth.uid())
    OR has_role(auth.uid(), 'super_admin')
  );

CREATE POLICY "owner writes permissions" ON public.module_permissions
  FOR ALL TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.workspaces w WHERE w.id = workspace_id AND w.owner_id = auth.uid())
    OR has_role(auth.uid(), 'super_admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.workspaces w WHERE w.id = workspace_id AND w.owner_id = auth.uid())
    OR has_role(auth.uid(), 'super_admin')
  );

CREATE TRIGGER touch_module_permissions BEFORE UPDATE ON public.module_permissions
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- RPC aceitar convite (security definer)
CREATE OR REPLACE FUNCTION public.accept_invitation(p_token uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  inv public.workspace_invitations%ROWTYPE;
  user_email text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  SELECT * INTO inv FROM public.workspace_invitations WHERE token = p_token;
  IF NOT FOUND THEN RAISE EXCEPTION 'invitation_not_found'; END IF;
  IF inv.status <> 'pending' THEN RAISE EXCEPTION 'invitation_not_pending'; END IF;
  IF inv.expires_at < now() THEN
    UPDATE public.workspace_invitations SET status = 'expired' WHERE id = inv.id;
    RAISE EXCEPTION 'invitation_expired';
  END IF;

  SELECT lower(email) INTO user_email FROM auth.users WHERE id = auth.uid();
  IF lower(inv.email) <> user_email THEN
    RAISE EXCEPTION 'email_mismatch';
  END IF;

  INSERT INTO public.workspace_members (workspace_id, user_id, role, role_type, is_partner)
  VALUES (inv.workspace_id, auth.uid(),
          CASE WHEN inv.role_type IN ('admin','gestor') THEN 'admin' ELSE 'member' END,
          inv.role_type, inv.is_partner)
  ON CONFLICT (workspace_id, user_id) DO UPDATE
    SET role_type = EXCLUDED.role_type, is_partner = EXCLUDED.is_partner;

  IF array_length(inv.modules, 1) IS NOT NULL THEN
    INSERT INTO public.module_permissions (workspace_id, user_id, modules)
    VALUES (inv.workspace_id, auth.uid(), inv.modules)
    ON CONFLICT (workspace_id, user_id) DO UPDATE SET modules = EXCLUDED.modules;
  END IF;

  UPDATE public.workspace_invitations
    SET status = 'accepted', accepted_at = now()
    WHERE id = inv.id;

  -- define como workspace ativo do usuário se não tiver
  UPDATE public.profiles SET current_workspace_id = inv.workspace_id
    WHERE id = auth.uid() AND current_workspace_id IS NULL;

  RETURN jsonb_build_object('workspace_id', inv.workspace_id, 'role_type', inv.role_type);
END;
$$;

GRANT EXECUTE ON FUNCTION public.accept_invitation(uuid) TO authenticated;

-- RPC para olhar convite por token sem estar logado ainda
CREATE OR REPLACE FUNCTION public.preview_invitation(p_token uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  inv public.workspace_invitations%ROWTYPE;
  ws_name text;
BEGIN
  SELECT * INTO inv FROM public.workspace_invitations WHERE token = p_token;
  IF NOT FOUND THEN RETURN NULL; END IF;
  SELECT name INTO ws_name FROM public.workspaces WHERE id = inv.workspace_id;
  RETURN jsonb_build_object(
    'email', inv.email,
    'role_type', inv.role_type,
    'is_partner', inv.is_partner,
    'status', inv.status,
    'expires_at', inv.expires_at,
    'workspace_name', ws_name
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.preview_invitation(uuid) TO anon, authenticated;
