
-- Adiciona campos de cadastro completo no profile
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS full_name text,
  ADD COLUMN IF NOT EXISTS cpf text,
  ADD COLUMN IF NOT EXISTS whatsapp_primary text,
  ADD COLUMN IF NOT EXISTS whatsapp_secondary text;

-- CPF único (1 conta por CPF)
CREATE UNIQUE INDEX IF NOT EXISTS profiles_cpf_unique_idx
  ON public.profiles (cpf)
  WHERE cpf IS NOT NULL;

-- Função de validação de CPF (algoritmo dos dígitos verificadores)
CREATE OR REPLACE FUNCTION public.is_valid_cpf(_cpf text)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  digits int[];
  i int;
  sum1 int := 0;
  sum2 int := 0;
  d1 int;
  d2 int;
  clean text;
BEGIN
  IF _cpf IS NULL THEN RETURN false; END IF;
  clean := regexp_replace(_cpf, '[^0-9]', '', 'g');
  IF length(clean) <> 11 THEN RETURN false; END IF;
  -- rejeita sequências iguais
  IF clean ~ '^(\d)\1{10}$' THEN RETURN false; END IF;
  digits := ARRAY(SELECT substr(clean, g, 1)::int FROM generate_series(1,11) g);
  FOR i IN 1..9 LOOP sum1 := sum1 + digits[i] * (11 - i); END LOOP;
  d1 := (sum1 * 10) % 11;
  IF d1 = 10 THEN d1 := 0; END IF;
  IF d1 <> digits[10] THEN RETURN false; END IF;
  FOR i IN 1..10 LOOP sum2 := sum2 + digits[i] * (12 - i); END LOOP;
  d2 := (sum2 * 10) % 11;
  IF d2 = 10 THEN d2 := 0; END IF;
  RETURN d2 = digits[11];
END;
$$;

-- Trigger de criação de usuário atualizado: lê metadata extra e valida CPF
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
begin
  email := lower(coalesce(new.email, ''));
  v_full_name := coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'display_name', split_part(email, '@', 1));
  display := v_full_name;
  username := split_part(email, '@', 1);
  v_cpf := new.raw_user_meta_data->>'cpf';
  v_wa1 := new.raw_user_meta_data->>'whatsapp_primary';
  v_wa2 := nullif(new.raw_user_meta_data->>'whatsapp_secondary', '');

  if v_cpf is not null then
    v_cpf_clean := regexp_replace(v_cpf, '[^0-9]', '', 'g');
    if not public.is_valid_cpf(v_cpf_clean) then
      raise exception 'CPF inválido';
    end if;
    if exists (select 1 from public.profiles where cpf = v_cpf_clean) then
      raise exception 'Já existe uma conta cadastrada com este CPF';
    end if;
  end if;

  insert into public.profiles (id, display_name, full_name, cpf, whatsapp_primary, whatsapp_secondary)
  values (new.id, display, v_full_name, v_cpf_clean, v_wa1, v_wa2)
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

  return new;
end;
$$;
