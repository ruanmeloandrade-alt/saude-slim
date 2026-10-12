
ALTER TABLE public.workspaces
ADD COLUMN IF NOT EXISTS business_hours jsonb NOT NULL DEFAULT jsonb_build_object(
  'timezone', 'America/Sao_Paulo',
  'days', jsonb_build_array(
    jsonb_build_object('enabled', false, 'start', '09:00', 'end', '18:00'),
    jsonb_build_object('enabled', true,  'start', '09:00', 'end', '18:00'),
    jsonb_build_object('enabled', true,  'start', '09:00', 'end', '18:00'),
    jsonb_build_object('enabled', true,  'start', '09:00', 'end', '18:00'),
    jsonb_build_object('enabled', true,  'start', '09:00', 'end', '18:00'),
    jsonb_build_object('enabled', true,  'start', '09:00', 'end', '18:00'),
    jsonb_build_object('enabled', false, 'start', '09:00', 'end', '13:00')
  )
);
