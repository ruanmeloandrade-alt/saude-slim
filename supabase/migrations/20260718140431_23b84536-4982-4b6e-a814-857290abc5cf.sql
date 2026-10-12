UPDATE public.ai_agent_settings SET mode = 'consultor' WHERE mode = 'manual';
UPDATE public.ai_agent_settings SET mode = 'gestor' WHERE mode IN ('semi_auto', 'auto');
ALTER TABLE public.ai_agent_settings ALTER COLUMN mode SET DEFAULT 'consultor';