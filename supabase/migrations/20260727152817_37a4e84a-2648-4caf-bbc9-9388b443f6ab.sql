ALTER TABLE public.crm_forms
  ADD COLUMN IF NOT EXISTS origem text NOT NULL DEFAULT 'mkton',
  ADD COLUMN IF NOT EXISTS ingest_token text,
  ADD COLUMN IF NOT EXISTS meta_form_id text,
  ADD COLUMN IF NOT EXISTS meta_page_id text,
  ADD COLUMN IF NOT EXISTS auto_criar_lead boolean NOT NULL DEFAULT true;

UPDATE public.crm_forms SET ingest_token = encode(gen_random_bytes(24), 'hex') WHERE ingest_token IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS crm_forms_ingest_token_key ON public.crm_forms (ingest_token);
CREATE INDEX IF NOT EXISTS crm_forms_meta_form_idx ON public.crm_forms (workspace_id, meta_form_id);

ALTER TABLE public.crm_forms
  ALTER COLUMN ingest_token SET DEFAULT encode(gen_random_bytes(24), 'hex');