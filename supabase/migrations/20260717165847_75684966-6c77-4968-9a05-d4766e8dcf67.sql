
ALTER TABLE public.companies
  ADD COLUMN IF NOT EXISTS cnpj text,
  ADD COLUMN IF NOT EXISTS logo_url text,
  ADD COLUMN IF NOT EXISTS phone text;

CREATE INDEX IF NOT EXISTS companies_ws_cnpj_idx
  ON public.companies (workspace_id, cnpj)
  WHERE cnpj IS NOT NULL;
