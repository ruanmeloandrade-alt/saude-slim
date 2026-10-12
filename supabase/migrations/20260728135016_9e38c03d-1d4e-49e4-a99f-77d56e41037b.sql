ALTER TABLE public.meta_automation_rules DROP CONSTRAINT meta_automation_rules_scope_type_check;
ALTER TABLE public.meta_automation_rules ADD CONSTRAINT meta_automation_rules_scope_type_check
CHECK (scope_type = ANY (ARRAY['workspace','ad_account','campaign','adset','ad']));
ALTER TABLE public.meta_automation_rules DROP CONSTRAINT meta_automation_rules_action_type_check;
ALTER TABLE public.meta_automation_rules ADD CONSTRAINT meta_automation_rules_action_type_check
CHECK (action_type = ANY (ARRAY['pause_campaign','activate_campaign','pause_adset','activate_adset','pause_ad','activate_ad','increase_budget','decrease_budget','duplicate_campaign','duplicate_adset','duplicate_ad','create_audience_from_source','create_lookalike_from_audience','duplicate_adset_with_audience','notify_only']));