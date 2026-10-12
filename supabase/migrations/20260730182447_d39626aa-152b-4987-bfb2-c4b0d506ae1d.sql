UPDATE public.plans SET
  description = 'CRM completo, automações, IA de atendimento e dashboard de indicadores.',
  modules = ARRAY['dashboard','extra_employee','suporte_chat','crm_mkton','agentes_ia']
WHERE code = 'starter';

UPDATE public.plans SET
  description = 'Tudo do Start + Fluxo de Trabalho e gestão de tarefas da equipe.',
  modules = ARRAY['dashboard','extra_employee','suporte_chat','crm_mkton','agentes_ia','fluxo_trabalho']
WHERE code = 'professional';

UPDATE public.plans SET
  description = 'Tudo do Growth + Tracking e rastreamento completo da jornada do lead.',
  modules = ARRAY['dashboard','extra_employee','suporte_chat','crm_mkton','agentes_ia','fluxo_trabalho','tracking','suporte_prioritario']
WHERE code = 'business';

UPDATE public.plans SET
  description = 'Tudo do Performance + Gestor de Tráfego IA e Social Media IA.',
  modules = ARRAY['dashboard','extra_employee','suporte_chat','crm_mkton','agentes_ia','fluxo_trabalho','tracking','suporte_prioritario','trafego_ia','social_media_ia']
WHERE code = 'enterprise';
