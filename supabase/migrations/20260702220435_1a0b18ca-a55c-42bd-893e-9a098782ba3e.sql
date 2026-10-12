
-- 1. pg_trgm para similaridade de nomes
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- 2. Colunas novas em profiles
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS company_name text,
  ADD COLUMN IF NOT EXISTS instagram_handle text,
  ADD COLUMN IF NOT EXISTS website_url text,
  ADD COLUMN IF NOT EXISTS role_in_company text,
  ADD COLUMN IF NOT EXISTS company_size text,
  ADD COLUMN IF NOT EXISTS acquisition_source text;

-- 3. Colunas novas em leads
ALTER TABLE public.leads
  ADD COLUMN IF NOT EXISTS custom_data jsonb NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS source text,
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'active',
  ADD COLUMN IF NOT EXISTS merged_into_id uuid REFERENCES public.leads(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS phone_normalized text
    GENERATED ALWAYS AS (regexp_replace(COALESCE(phone,''), '\D', '', 'g')) STORED;

CREATE INDEX IF NOT EXISTS leads_ws_phone_norm_idx
  ON public.leads (workspace_id, phone_normalized)
  WHERE phone_normalized <> '' AND status = 'active';
CREATE INDEX IF NOT EXISTS leads_ws_email_lower_idx
  ON public.leads (workspace_id, lower(email))
  WHERE email IS NOT NULL AND status = 'active';
CREATE INDEX IF NOT EXISTS leads_ws_name_trgm_idx
  ON public.leads USING gin (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS leads_status_idx ON public.leads (workspace_id, status);

-- 4. Tabela de grupos dispensados na dedupe
CREATE TABLE IF NOT EXISTS public.lead_dedupe_dismissals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  signature text NOT NULL,
  dismissed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (workspace_id, signature)
);
GRANT SELECT, INSERT, DELETE ON public.lead_dedupe_dismissals TO authenticated;
GRANT ALL ON public.lead_dedupe_dismissals TO service_role;
ALTER TABLE public.lead_dedupe_dismissals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ws read dedupe dismissals"
  ON public.lead_dedupe_dismissals FOR SELECT TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE POLICY "ws write dedupe dismissals"
  ON public.lead_dedupe_dismissals FOR INSERT TO authenticated
  WITH CHECK (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));
CREATE POLICY "ws delete dedupe dismissals"
  ON public.lead_dedupe_dismissals FOR DELETE TO authenticated
  USING (public.is_workspace_member(workspace_id, auth.uid()) OR public.has_role(auth.uid(),'super_admin'));

-- 5. Garante pipeline "Cadastros MKTOn" no workspace do super_admin
DO $$
DECLARE
  admin_ws uuid;
  admin_source uuid;
  pipe_id uuid;
BEGIN
  SELECT w.id INTO admin_ws
    FROM public.workspaces w
    JOIN public.user_roles ur ON ur.user_id = w.owner_id AND ur.role = 'super_admin'
    ORDER BY w.created_at ASC
    LIMIT 1;
  IF admin_ws IS NULL THEN RETURN; END IF;

  SELECT id INTO admin_source FROM public.crm_sources
    WHERE workspace_id = admin_ws AND provider = 'mkton' LIMIT 1;
  IF admin_source IS NULL THEN
    INSERT INTO public.crm_sources (workspace_id, provider, display_name, is_default)
    VALUES (admin_ws, 'mkton', 'MktOn', true) RETURNING id INTO admin_source;
  END IF;

  SELECT id INTO pipe_id FROM public.pipelines
    WHERE workspace_id = admin_ws AND name = 'Cadastros MKTOn' LIMIT 1;
  IF pipe_id IS NULL THEN
    INSERT INTO public.pipelines (workspace_id, crm_source_id, name, position)
    VALUES (admin_ws, admin_source, 'Cadastros MKTOn', 999)
    RETURNING id INTO pipe_id;

    INSERT INTO public.pipeline_stages (workspace_id, pipeline_id, name, position, color) VALUES
      (admin_ws, pipe_id, 'Novo cadastro',    0, '#a855f7'),
      (admin_ws, pipe_id, 'Em trial',         1, '#6366f1'),
      (admin_ws, pipe_id, 'Assinou',          2, '#22c55e'),
      (admin_ws, pipe_id, 'Trial expirado',   3, '#ef4444');
  END IF;
END $$;

-- 6. Atualiza handle_new_user: novos campos + lead automático no CRM do ADM
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
declare
  username text;
  ws_slug text;
  ws_id uuid;
  display text;
  email text;
  v_full_name text;
  v_cpf text;
  v_cpf_clean text;
  v_wa1 text;
  v_wa2 text;
  v_country text;
  v_niche text;
  v_company text;
  v_instagram text;
  v_website text;
  v_role text;
  v_company_size text;
  v_acq text;
  admin_ws uuid;
  admin_source uuid;
  admin_pipe uuid;
  admin_stage uuid;
  existing_lead_id uuid;
  new_custom jsonb;
  wa_digits text;
  email_lower text;
begin
  email := lower(coalesce(new.email, ''));
  email_lower := email;
  v_full_name := coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'display_name', split_part(email, '@', 1));
  display := v_full_name;
  username := split_part(email, '@', 1);
  v_cpf := nullif(new.raw_user_meta_data->>'cpf', '');
  v_wa1 := new.raw_user_meta_data->>'whatsapp_primary';
  v_wa2 := nullif(new.raw_user_meta_data->>'whatsapp_secondary', '');
  v_country := nullif(new.raw_user_meta_data->>'country', '');
  v_niche := nullif(new.raw_user_meta_data->>'niche', '');
  v_company := nullif(new.raw_user_meta_data->>'company_name', '');
  v_instagram := nullif(regexp_replace(lower(coalesce(new.raw_user_meta_data->>'instagram_handle','')), '^@', ''), '');
  v_website := nullif(new.raw_user_meta_data->>'website_url', '');
  v_role := nullif(new.raw_user_meta_data->>'role_in_company', '');
  v_company_size := nullif(new.raw_user_meta_data->>'company_size', '');
  v_acq := nullif(new.raw_user_meta_data->>'acquisition_source', '');

  if v_cpf is not null then
    v_cpf_clean := regexp_replace(v_cpf, '[^0-9]', '', 'g');
    if length(v_cpf_clean) = 11 then
      if not public.is_valid_cpf(v_cpf_clean) then
        raise exception 'CPF inválido';
      end if;
      if exists (select 1 from public.profiles where cpf = v_cpf_clean) then
        raise exception 'Já existe uma conta cadastrada com este CPF';
      end if;
    else
      v_cpf_clean := null;
    end if;
  end if;

  insert into public.profiles (
    id, display_name, full_name, cpf, whatsapp_primary, whatsapp_secondary,
    country, niche, company_name, instagram_handle, website_url, role_in_company,
    company_size, acquisition_source
  ) values (
    new.id, display, v_full_name, v_cpf_clean, v_wa1, v_wa2,
    v_country, v_niche, v_company, v_instagram, v_website, v_role,
    v_company_size, v_acq
  )
  on conflict (id) do nothing;

  ws_slug := public.generate_workspace_slug(username);
  insert into public.workspaces (slug, name, owner_id)
  values (ws_slug, display, new.id)
  returning id into ws_id;

  insert into public.workspace_members (workspace_id, user_id, role)
  values (ws_id, new.id, 'owner');

  update public.profiles set current_workspace_id = ws_id where id = new.id;

  if email = 'ruanandradenegocios@hotmail.com' then
    insert into public.user_roles (user_id, role) values (new.id, 'super_admin')
    on conflict do nothing;
  end if;

  -- Cria lead no CRM do Super ADM (isolado; nunca falha o signup)
  begin
    SELECT w.id INTO admin_ws
      FROM public.workspaces w
      JOIN public.user_roles ur ON ur.user_id = w.owner_id AND ur.role = 'super_admin'
      ORDER BY w.created_at ASC
      LIMIT 1;

    IF admin_ws IS NOT NULL AND admin_ws <> ws_id THEN
      SELECT id INTO admin_source FROM public.crm_sources
        WHERE workspace_id = admin_ws AND provider = 'mkton' LIMIT 1;
      SELECT id INTO admin_pipe FROM public.pipelines
        WHERE workspace_id = admin_ws AND name = 'Cadastros MKTOn' LIMIT 1;
      SELECT id INTO admin_stage FROM public.pipeline_stages
        WHERE pipeline_id = admin_pipe ORDER BY position ASC LIMIT 1;

      IF admin_source IS NOT NULL THEN
        wa_digits := regexp_replace(coalesce(v_wa1,''), '\D', '', 'g');
        new_custom := jsonb_strip_nulls(jsonb_build_object(
          'company_name', v_company,
          'instagram_handle', v_instagram,
          'website_url', v_website,
          'country', v_country,
          'niche', v_niche,
          'role_in_company', v_role,
          'company_size', v_company_size,
          'acquisition_source', v_acq,
          'whatsapp_secondary', v_wa2,
          'signup_user_id', new.id::text,
          'signup_at', to_char(now() at time zone 'utc','YYYY-MM-DD"T"HH24:MI:SS"Z"')
        ));

        -- Dedupe: se já existir lead com mesmo email OU telefone, faz upsert do custom_data
        SELECT id INTO existing_lead_id FROM public.leads
         WHERE workspace_id = admin_ws AND status = 'active'
           AND (
             (email_lower <> '' AND lower(email) = email_lower)
             OR (length(wa_digits) >= 8 AND phone_normalized = wa_digits)
           )
         ORDER BY created_at ASC
         LIMIT 1;

        IF existing_lead_id IS NOT NULL THEN
          UPDATE public.leads
             SET custom_data = coalesce(custom_data,'{}'::jsonb)
                             || jsonb_build_object(
                                  'signups', coalesce(custom_data->'signups','[]'::jsonb) || jsonb_build_array(new_custom)
                                ),
                 email = coalesce(email, email_lower),
                 phone = coalesce(phone, v_wa1),
                 name  = case when isnumeric_or_empty(name) then v_full_name else name end,
                 updated_at = now()
           WHERE id = existing_lead_id;

          INSERT INTO public.lead_activities (workspace_id, lead_id, type, payload)
          VALUES (admin_ws, existing_lead_id, 'signup_repeat',
                  jsonb_build_object('email', email_lower, 'phone', v_wa1));
        ELSE
          INSERT INTO public.leads (workspace_id, crm_source_id, pipeline_id, stage_id,
                                    name, email, phone, value, source, custom_data)
          VALUES (admin_ws, admin_source, admin_pipe, admin_stage,
                  v_full_name, nullif(email_lower,''), v_wa1, 0, 'cadastro-mkton', new_custom)
          RETURNING id INTO existing_lead_id;

          INSERT INTO public.lead_activities (workspace_id, lead_id, type, payload)
          VALUES (admin_ws, existing_lead_id, 'signup',
                  jsonb_build_object('email', email_lower, 'phone', v_wa1, 'company', v_company));
        END IF;
      END IF;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'handle_new_user: falha ao criar lead ADM: %', SQLERRM;
  end;

  return new;
end;
$$;

-- helper leve usada acima (nome mais confiável apenas se atual for placeholder)
CREATE OR REPLACE FUNCTION public.isnumeric_or_empty(_t text)
RETURNS boolean LANGUAGE sql IMMUTABLE AS $$
  SELECT _t IS NULL OR btrim(_t) = '' OR _t ~ '^\+?[\d\s().-]{6,}$'
$$;
