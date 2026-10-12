
-- 1) Novos campos no cadastro
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS country text,
  ADD COLUMN IF NOT EXISTS niche text;

-- 2) handle_new_user aceita cadastro internacional (CPF opcional) + salva país/nicho
CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
begin
  email := lower(coalesce(new.email, ''));
  v_full_name := coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'display_name', split_part(email, '@', 1));
  display := v_full_name;
  username := split_part(email, '@', 1);
  v_cpf := nullif(new.raw_user_meta_data->>'cpf', '');
  v_wa1 := new.raw_user_meta_data->>'whatsapp_primary';
  v_wa2 := nullif(new.raw_user_meta_data->>'whatsapp_secondary', '');
  v_country := nullif(new.raw_user_meta_data->>'country', '');
  v_niche := nullif(new.raw_user_meta_data->>'niche', '');

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

  insert into public.profiles (id, display_name, full_name, cpf, whatsapp_primary, whatsapp_secondary, country, niche)
  values (new.id, display, v_full_name, v_cpf_clean, v_wa1, v_wa2, v_country, v_niche)
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
$function$;
