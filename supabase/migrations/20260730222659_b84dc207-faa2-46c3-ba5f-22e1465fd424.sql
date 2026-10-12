ALTER TABLE public.salesbots DROP CONSTRAINT IF EXISTS salesbots_scope_check;
UPDATE public.salesbots SET scope = 'individual' WHERE scope IS NULL OR scope NOT IN ('individual','grupo');
ALTER TABLE public.salesbots ALTER COLUMN scope SET DEFAULT 'individual';
ALTER TABLE public.salesbots ADD CONSTRAINT salesbots_scope_check CHECK (scope IN ('individual','grupo'));