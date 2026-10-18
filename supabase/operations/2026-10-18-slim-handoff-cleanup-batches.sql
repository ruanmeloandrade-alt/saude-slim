-- Reviewed operational cleanup fallback after execute_sql requestState errors.
-- Run each block in order and reconcile its receipt before the next.
-- The completed exact job deletion is recorded separately in the task scope.
-- Each block is atomic and locks the workspace row; the four-block sequence is not one transaction.

-- SLIM-HANDOFF-20261018 / explicit bounded block 1/4.
-- Same authorized workspace and reviewed child-before-parent allowlist.
WITH authorized AS MATERIALIZED (
  SELECT w.id FROM public.workspaces w
  WHERE w.id='c49945db-1960-461a-9339-a43b8403bdd9' AND w.owner_id='faaad2a3-52ef-41a6-846b-ee1f64f3ed38'
    AND (SELECT count(*) FROM public.workspace_members m JOIN public.profiles p ON p.id=m.user_id JOIN auth.users u ON u.id=m.user_id
         WHERE m.workspace_id=w.id AND m.user_id IN ('ef744fda-72b1-4cc5-b06e-76f9610a01c6','e8f2252b-c0bc-4336-9912-2e62e73ddd2e')
           AND m.role='admin' AND m.role_type='admin' AND p.current_workspace_id=w.id
           AND (m.access_expires_at IS NULL OR m.access_expires_at>now())
           AND u.email_confirmed_at IS NOT NULL AND u.deleted_at IS NULL
           AND (u.banned_until IS NULL OR u.banned_until<now()))=2
    AND (SELECT count(*) FROM public.whatsapp_web_sessions WHERE workspace_id=w.id)=5
    AND (SELECT count(*) FROM public.whatsapp_web_sessions WHERE workspace_id=w.id AND id IN ('33ecf991-003a-4e8d-95f3-3c255f550ae0','4334a4dd-ac29-4950-b496-721c2275553d','63a9d9af-3f8e-483e-9edc-99f4be1d146f','7e92dc1a-af8a-4b89-ae86-b0f26f583db4','9b0d5aa4-8f0f-425e-b7a7-5570c635fd15') AND status='desconectado' AND metadata->>'deleted'='true')=5
    AND NOT EXISTS (SELECT 1 FROM public.salesbots WHERE workspace_id=w.id AND is_active)
    AND NOT EXISTS (SELECT 1 FROM public.conversation_ai_agents WHERE workspace_id=w.id AND enabled)
    AND NOT EXISTS (SELECT 1 FROM public.group_ai_agents WHERE workspace_id=w.id AND enabled)
    AND NOT EXISTS (SELECT 1 FROM public.crm_stage_automations WHERE workspace_id=w.id AND enabled)
    AND NOT EXISTS (SELECT 1 FROM public.crm_automation_jobs WHERE workspace_id=w.id AND status IN ('pending','running'))
    AND (SELECT count(*) FROM public.crm_stage_automations WHERE workspace_id=w.id) <= 1
    AND (SELECT count(*) FROM public.slim_stage_move_events WHERE workspace_id=w.id) <= 2
    AND (SELECT count(*) FROM public.slim_audience_deliveries WHERE workspace_id=w.id) <= 2
    AND (SELECT count(*) FROM public.slim_audience_campaigns WHERE workspace_id=w.id) <= 2
    AND (SELECT count(*) FROM public.crm_lead_audiences WHERE workspace_id=w.id) <= 1
    AND (SELECT count(*) FROM public.slim_order_document_deliveries WHERE workspace_id=w.id) <= 0
    AND (SELECT count(*) FROM public.slim_order_documents WHERE workspace_id=w.id) <= 0
    AND (SELECT count(*) FROM public.slim_order_changes WHERE workspace_id=w.id) <= 0
    AND (SELECT count(*) FROM public.slim_stock_movements WHERE workspace_id=w.id) <= 4
    AND (SELECT count(*) FROM public.slim_checkout_attempt_closures WHERE workspace_id=w.id) <= 0
    AND (SELECT count(*) FROM public.slim_orders WHERE workspace_id=w.id) <= 2
    AND (SELECT count(*) FROM public.salesbot_run_logs WHERE workspace_id=w.id) <= 17
  FOR UPDATE OF w
), removed_0 AS (
  DELETE FROM public.crm_stage_automations WHERE workspace_id IN (SELECT id FROM authorized) RETURNING 1
), removed_1 AS (
  DELETE FROM public.slim_stage_move_events WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_0)>=0 RETURNING 1
), removed_2 AS (
  DELETE FROM public.slim_audience_deliveries WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_1)>=0 RETURNING 1
), removed_3 AS (
  DELETE FROM public.slim_audience_campaigns WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_2)>=0 RETURNING 1
), removed_4 AS (
  DELETE FROM public.crm_lead_audiences WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_3)>=0 RETURNING 1
), removed_5 AS (
  DELETE FROM public.slim_order_document_deliveries WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_4)>=0 RETURNING 1
), removed_6 AS (
  DELETE FROM public.slim_order_documents WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_5)>=0 RETURNING 1
), removed_7 AS (
  DELETE FROM public.slim_order_changes WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_6)>=0 RETURNING 1
), removed_8 AS (
  DELETE FROM public.slim_stock_movements WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_7)>=0 RETURNING 1
), removed_9 AS (
  DELETE FROM public.slim_checkout_attempt_closures WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_8)>=0 RETURNING 1
), removed_10 AS (
  DELETE FROM public.slim_orders WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_9)>=0 RETURNING 1
), removed_11 AS (
  DELETE FROM public.salesbot_run_logs WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_10)>=0 RETURNING 1
)
SELECT jsonb_build_object('block',1,'authorized',(SELECT count(*) FROM authorized)=1,'deleted',jsonb_build_object(
  'crm_stage_automations',(SELECT count(*) FROM removed_0),
  'slim_stage_move_events',(SELECT count(*) FROM removed_1),
  'slim_audience_deliveries',(SELECT count(*) FROM removed_2),
  'slim_audience_campaigns',(SELECT count(*) FROM removed_3),
  'crm_lead_audiences',(SELECT count(*) FROM removed_4),
  'slim_order_document_deliveries',(SELECT count(*) FROM removed_5),
  'slim_order_documents',(SELECT count(*) FROM removed_6),
  'slim_order_changes',(SELECT count(*) FROM removed_7),
  'slim_stock_movements',(SELECT count(*) FROM removed_8),
  'slim_checkout_attempt_closures',(SELECT count(*) FROM removed_9),
  'slim_orders',(SELECT count(*) FROM removed_10),
  'salesbot_run_logs',(SELECT count(*) FROM removed_11)
)) AS cleanup_result;


-- SLIM-HANDOFF-20261018 / explicit bounded block 2/4.
-- Same authorized workspace and reviewed child-before-parent allowlist.
WITH authorized AS MATERIALIZED (
  SELECT w.id FROM public.workspaces w
  WHERE w.id='c49945db-1960-461a-9339-a43b8403bdd9' AND w.owner_id='faaad2a3-52ef-41a6-846b-ee1f64f3ed38'
    AND (SELECT count(*) FROM public.workspace_members m JOIN public.profiles p ON p.id=m.user_id JOIN auth.users u ON u.id=m.user_id
         WHERE m.workspace_id=w.id AND m.user_id IN ('ef744fda-72b1-4cc5-b06e-76f9610a01c6','e8f2252b-c0bc-4336-9912-2e62e73ddd2e')
           AND m.role='admin' AND m.role_type='admin' AND p.current_workspace_id=w.id
           AND (m.access_expires_at IS NULL OR m.access_expires_at>now())
           AND u.email_confirmed_at IS NOT NULL AND u.deleted_at IS NULL
           AND (u.banned_until IS NULL OR u.banned_until<now()))=2
    AND (SELECT count(*) FROM public.whatsapp_web_sessions WHERE workspace_id=w.id)=5
    AND (SELECT count(*) FROM public.whatsapp_web_sessions WHERE workspace_id=w.id AND id IN ('33ecf991-003a-4e8d-95f3-3c255f550ae0','4334a4dd-ac29-4950-b496-721c2275553d','63a9d9af-3f8e-483e-9edc-99f4be1d146f','7e92dc1a-af8a-4b89-ae86-b0f26f583db4','9b0d5aa4-8f0f-425e-b7a7-5570c635fd15') AND status='desconectado' AND metadata->>'deleted'='true')=5
    AND NOT EXISTS (SELECT 1 FROM public.salesbots WHERE workspace_id=w.id AND is_active)
    AND NOT EXISTS (SELECT 1 FROM public.conversation_ai_agents WHERE workspace_id=w.id AND enabled)
    AND NOT EXISTS (SELECT 1 FROM public.group_ai_agents WHERE workspace_id=w.id AND enabled)
    AND NOT EXISTS (SELECT 1 FROM public.crm_stage_automations WHERE workspace_id=w.id AND enabled)
    AND NOT EXISTS (SELECT 1 FROM public.crm_automation_jobs WHERE workspace_id=w.id AND status IN ('pending','running'))
    AND (SELECT count(*) FROM public.salesbot_runs WHERE workspace_id=w.id) <= 6
    AND (SELECT count(*) FROM public.salesbot_blocks WHERE workspace_id=w.id) <= 6
    AND (SELECT count(*) FROM public.salesbot_revisions WHERE workspace_id=w.id) <= 13
    AND (SELECT count(*) FROM public.salesbots WHERE workspace_id=w.id) <= 3
    AND (SELECT count(*) FROM public.conversation_agent_runs WHERE workspace_id=w.id) <= 0
    AND (SELECT count(*) FROM public.conversation_ai_agents WHERE workspace_id=w.id) <= 1
    AND (SELECT count(*) FROM public.group_ai_agents WHERE workspace_id=w.id) <= 0
    AND (SELECT count(*) FROM public.inbox_label_assignments WHERE workspace_id=w.id) <= 0
    AND (SELECT count(*) FROM public.inbox_labels WHERE workspace_id=w.id) <= 0
    AND (SELECT count(*) FROM public.whatsapp_groups WHERE workspace_id=w.id) <= 40
    AND (SELECT count(*) FROM public.whatsapp_web_messages WHERE workspace_id=w.id) <= 360
    AND (SELECT count(*) FROM public.lead_activities WHERE workspace_id=w.id) <= 439
  FOR UPDATE OF w
), removed_0 AS (
  DELETE FROM public.salesbot_runs WHERE workspace_id IN (SELECT id FROM authorized) RETURNING 1
), removed_1 AS (
  DELETE FROM public.salesbot_blocks WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_0)>=0 RETURNING 1
), removed_2 AS (
  DELETE FROM public.salesbot_revisions WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_1)>=0 RETURNING 1
), removed_3 AS (
  DELETE FROM public.salesbots WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_2)>=0 RETURNING 1
), removed_4 AS (
  DELETE FROM public.conversation_agent_runs WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_3)>=0 RETURNING 1
), removed_5 AS (
  DELETE FROM public.conversation_ai_agents WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_4)>=0 RETURNING 1
), removed_6 AS (
  DELETE FROM public.group_ai_agents WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_5)>=0 RETURNING 1
), removed_7 AS (
  DELETE FROM public.inbox_label_assignments WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_6)>=0 RETURNING 1
), removed_8 AS (
  DELETE FROM public.inbox_labels WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_7)>=0 RETURNING 1
), removed_9 AS (
  DELETE FROM public.whatsapp_groups WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_8)>=0 RETURNING 1
), removed_10 AS (
  DELETE FROM public.whatsapp_web_messages WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_9)>=0 RETURNING 1
), removed_11 AS (
  DELETE FROM public.lead_activities WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_10)>=0 RETURNING 1
)
SELECT jsonb_build_object('block',2,'authorized',(SELECT count(*) FROM authorized)=1,'deleted',jsonb_build_object(
  'salesbot_runs',(SELECT count(*) FROM removed_0),
  'salesbot_blocks',(SELECT count(*) FROM removed_1),
  'salesbot_revisions',(SELECT count(*) FROM removed_2),
  'salesbots',(SELECT count(*) FROM removed_3),
  'conversation_agent_runs',(SELECT count(*) FROM removed_4),
  'conversation_ai_agents',(SELECT count(*) FROM removed_5),
  'group_ai_agents',(SELECT count(*) FROM removed_6),
  'inbox_label_assignments',(SELECT count(*) FROM removed_7),
  'inbox_labels',(SELECT count(*) FROM removed_8),
  'whatsapp_groups',(SELECT count(*) FROM removed_9),
  'whatsapp_web_messages',(SELECT count(*) FROM removed_10),
  'lead_activities',(SELECT count(*) FROM removed_11)
)) AS cleanup_result;


-- SLIM-HANDOFF-20261018 / explicit bounded block 3/4.
-- Same authorized workspace and reviewed child-before-parent allowlist.
WITH authorized AS MATERIALIZED (
  SELECT w.id FROM public.workspaces w
  WHERE w.id='c49945db-1960-461a-9339-a43b8403bdd9' AND w.owner_id='faaad2a3-52ef-41a6-846b-ee1f64f3ed38'
    AND (SELECT count(*) FROM public.workspace_members m JOIN public.profiles p ON p.id=m.user_id JOIN auth.users u ON u.id=m.user_id
         WHERE m.workspace_id=w.id AND m.user_id IN ('ef744fda-72b1-4cc5-b06e-76f9610a01c6','e8f2252b-c0bc-4336-9912-2e62e73ddd2e')
           AND m.role='admin' AND m.role_type='admin' AND p.current_workspace_id=w.id
           AND (m.access_expires_at IS NULL OR m.access_expires_at>now())
           AND u.email_confirmed_at IS NOT NULL AND u.deleted_at IS NULL
           AND (u.banned_until IS NULL OR u.banned_until<now()))=2
    AND (SELECT count(*) FROM public.whatsapp_web_sessions WHERE workspace_id=w.id)=5
    AND (SELECT count(*) FROM public.whatsapp_web_sessions WHERE workspace_id=w.id AND id IN ('33ecf991-003a-4e8d-95f3-3c255f550ae0','4334a4dd-ac29-4950-b496-721c2275553d','63a9d9af-3f8e-483e-9edc-99f4be1d146f','7e92dc1a-af8a-4b89-ae86-b0f26f583db4','9b0d5aa4-8f0f-425e-b7a7-5570c635fd15') AND status='desconectado' AND metadata->>'deleted'='true')=5
    AND NOT EXISTS (SELECT 1 FROM public.salesbots WHERE workspace_id=w.id AND is_active)
    AND NOT EXISTS (SELECT 1 FROM public.conversation_ai_agents WHERE workspace_id=w.id AND enabled)
    AND NOT EXISTS (SELECT 1 FROM public.group_ai_agents WHERE workspace_id=w.id AND enabled)
    AND NOT EXISTS (SELECT 1 FROM public.crm_stage_automations WHERE workspace_id=w.id AND enabled)
    AND NOT EXISTS (SELECT 1 FROM public.crm_automation_jobs WHERE workspace_id=w.id AND status IN ('pending','running'))
    AND (SELECT count(*) FROM public.lead_products WHERE workspace_id=w.id) <= 2
    AND (SELECT count(*) FROM public.lead_custom_field_values WHERE workspace_id=w.id) <= 0
    AND (SELECT count(*) FROM public.tasks WHERE workspace_id=w.id) <= 0
    AND (SELECT count(*) FROM public.crm_form_submissions WHERE workspace_id=w.id) <= 0
    AND (SELECT count(*) FROM public.tracking_conversion_events WHERE workspace_id=w.id) <= 0
    AND (SELECT count(*) FROM public.tracking_events WHERE workspace_id=w.id) <= 0
    AND (SELECT count(*) FROM public.tracking_sites WHERE workspace_id=w.id) <= 0
    AND (SELECT count(*) FROM public.crm_forms WHERE workspace_id=w.id) <= 1
    AND (SELECT count(*) FROM public.supplier_product_costs WHERE workspace_id=w.id) <= 1
    AND (SELECT count(*) FROM public.products WHERE workspace_id=w.id) <= 1
    AND (SELECT count(*) FROM public.lead_dedupe_dismissals WHERE workspace_id=w.id) <= 0
    AND (SELECT count(*) FROM public.leads WHERE workspace_id=w.id) <= 26
  FOR UPDATE OF w
), removed_0 AS (
  DELETE FROM public.lead_products WHERE workspace_id IN (SELECT id FROM authorized) RETURNING 1
), removed_1 AS (
  DELETE FROM public.lead_custom_field_values WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_0)>=0 RETURNING 1
), removed_2 AS (
  DELETE FROM public.tasks WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_1)>=0 RETURNING 1
), removed_3 AS (
  DELETE FROM public.crm_form_submissions WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_2)>=0 RETURNING 1
), removed_4 AS (
  DELETE FROM public.tracking_conversion_events WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_3)>=0 RETURNING 1
), removed_5 AS (
  DELETE FROM public.tracking_events WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_4)>=0 RETURNING 1
), removed_6 AS (
  DELETE FROM public.tracking_sites WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_5)>=0 RETURNING 1
), removed_7 AS (
  DELETE FROM public.crm_forms WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_6)>=0 RETURNING 1
), removed_8 AS (
  DELETE FROM public.supplier_product_costs WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_7)>=0 RETURNING 1
), removed_9 AS (
  DELETE FROM public.products WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_8)>=0 RETURNING 1
), removed_10 AS (
  DELETE FROM public.lead_dedupe_dismissals WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_9)>=0 RETURNING 1
), removed_11 AS (
  DELETE FROM public.leads WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_10)>=0 RETURNING 1
)
SELECT jsonb_build_object('block',3,'authorized',(SELECT count(*) FROM authorized)=1,'deleted',jsonb_build_object(
  'lead_products',(SELECT count(*) FROM removed_0),
  'lead_custom_field_values',(SELECT count(*) FROM removed_1),
  'tasks',(SELECT count(*) FROM removed_2),
  'crm_form_submissions',(SELECT count(*) FROM removed_3),
  'tracking_conversion_events',(SELECT count(*) FROM removed_4),
  'tracking_events',(SELECT count(*) FROM removed_5),
  'tracking_sites',(SELECT count(*) FROM removed_6),
  'crm_forms',(SELECT count(*) FROM removed_7),
  'supplier_product_costs',(SELECT count(*) FROM removed_8),
  'products',(SELECT count(*) FROM removed_9),
  'lead_dedupe_dismissals',(SELECT count(*) FROM removed_10),
  'leads',(SELECT count(*) FROM removed_11)
)) AS cleanup_result;


-- SLIM-HANDOFF-20261018 / explicit bounded block 4/4.
-- Same authorized workspace and reviewed child-before-parent allowlist.
WITH authorized AS MATERIALIZED (
  SELECT w.id FROM public.workspaces w
  WHERE w.id='c49945db-1960-461a-9339-a43b8403bdd9' AND w.owner_id='faaad2a3-52ef-41a6-846b-ee1f64f3ed38'
    AND (SELECT count(*) FROM public.workspace_members m JOIN public.profiles p ON p.id=m.user_id JOIN auth.users u ON u.id=m.user_id
         WHERE m.workspace_id=w.id AND m.user_id IN ('ef744fda-72b1-4cc5-b06e-76f9610a01c6','e8f2252b-c0bc-4336-9912-2e62e73ddd2e')
           AND m.role='admin' AND m.role_type='admin' AND p.current_workspace_id=w.id
           AND (m.access_expires_at IS NULL OR m.access_expires_at>now())
           AND u.email_confirmed_at IS NOT NULL AND u.deleted_at IS NULL
           AND (u.banned_until IS NULL OR u.banned_until<now()))=2
    AND (SELECT count(*) FROM public.whatsapp_web_sessions WHERE workspace_id=w.id)=5
    AND (SELECT count(*) FROM public.whatsapp_web_sessions WHERE workspace_id=w.id AND id IN ('33ecf991-003a-4e8d-95f3-3c255f550ae0','4334a4dd-ac29-4950-b496-721c2275553d','63a9d9af-3f8e-483e-9edc-99f4be1d146f','7e92dc1a-af8a-4b89-ae86-b0f26f583db4','9b0d5aa4-8f0f-425e-b7a7-5570c635fd15') AND status='desconectado' AND metadata->>'deleted'='true')=5
    AND NOT EXISTS (SELECT 1 FROM public.salesbots WHERE workspace_id=w.id AND is_active)
    AND NOT EXISTS (SELECT 1 FROM public.conversation_ai_agents WHERE workspace_id=w.id AND enabled)
    AND NOT EXISTS (SELECT 1 FROM public.group_ai_agents WHERE workspace_id=w.id AND enabled)
    AND NOT EXISTS (SELECT 1 FROM public.crm_stage_automations WHERE workspace_id=w.id AND enabled)
    AND NOT EXISTS (SELECT 1 FROM public.crm_automation_jobs WHERE workspace_id=w.id AND status IN ('pending','running'))
    AND (SELECT count(*) FROM public.companies WHERE workspace_id=w.id) <= 1
    AND (SELECT count(*) FROM public.lead_custom_fields WHERE workspace_id=w.id) <= 0
    AND (SELECT count(*) FROM public.ai_brain_chunks WHERE workspace_id=w.id) <= 0
    AND (SELECT count(*) FROM public.ai_brain_sources WHERE workspace_id=w.id) <= 0
    AND (SELECT count(*) FROM public.ai_brain_blocked_terms WHERE workspace_id=w.id) <= 0
    AND (SELECT count(*) FROM public.ai_agent_conversations WHERE workspace_id=w.id) <= 0
    AND (SELECT count(*) FROM public.ai_agent_settings WHERE workspace_id=w.id) <= 0
    AND (SELECT count(*) FROM public.support_robot_messages WHERE workspace_id=w.id) <= 21
    AND (SELECT count(*) FROM public.integrations WHERE workspace_id=w.id) <= 1
    AND (SELECT count(*) FROM public.whatsapp_web_sessions WHERE workspace_id=w.id) <= 5
    AND (SELECT count(*) FROM public.pipeline_stages WHERE workspace_id=w.id)=5
    AND (SELECT count(*) FROM public.crm_sources WHERE workspace_id=w.id)=2
  FOR UPDATE OF w
), removed_0 AS (
  DELETE FROM public.companies WHERE workspace_id IN (SELECT id FROM authorized) RETURNING 1
), removed_1 AS (
  DELETE FROM public.lead_custom_fields WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_0)>=0 RETURNING 1
), removed_2 AS (
  DELETE FROM public.ai_brain_chunks WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_1)>=0 RETURNING 1
), removed_3 AS (
  DELETE FROM public.ai_brain_sources WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_2)>=0 RETURNING 1
), removed_4 AS (
  DELETE FROM public.ai_brain_blocked_terms WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_3)>=0 RETURNING 1
), removed_5 AS (
  DELETE FROM public.ai_agent_conversations WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_4)>=0 RETURNING 1
), removed_6 AS (
  DELETE FROM public.ai_agent_settings WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_5)>=0 RETURNING 1
), removed_7 AS (
  DELETE FROM public.support_robot_messages WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_6)>=0 RETURNING 1
), removed_8 AS (
  DELETE FROM public.integrations WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_7)>=0 RETURNING 1
), removed_9 AS (
  DELETE FROM public.whatsapp_web_sessions WHERE workspace_id IN (SELECT id FROM authorized) AND (SELECT count(*) FROM removed_8)>=0 RETURNING 1
), removed_10 AS (
  DELETE FROM public.pipeline_stages WHERE workspace_id IN (SELECT id FROM authorized) AND id='e50a49f6-22d4-4d3b-8d97-6a47f1d2b45d' AND (SELECT count(*) FROM removed_9)>=0 RETURNING 1
), removed_11 AS (
  DELETE FROM public.crm_sources WHERE workspace_id IN (SELECT id FROM authorized) AND id='e301f396-4022-4b6a-91b0-a140cbbffc1b' AND NOT is_default AND (SELECT count(*) FROM removed_10)>=0 RETURNING 1
)
SELECT jsonb_build_object('block',4,'authorized',(SELECT count(*) FROM authorized)=1,'deleted',jsonb_build_object(
  'companies',(SELECT count(*) FROM removed_0),
  'lead_custom_fields',(SELECT count(*) FROM removed_1),
  'ai_brain_chunks',(SELECT count(*) FROM removed_2),
  'ai_brain_sources',(SELECT count(*) FROM removed_3),
  'ai_brain_blocked_terms',(SELECT count(*) FROM removed_4),
  'ai_agent_conversations',(SELECT count(*) FROM removed_5),
  'ai_agent_settings',(SELECT count(*) FROM removed_6),
  'support_robot_messages',(SELECT count(*) FROM removed_7),
  'integrations',(SELECT count(*) FROM removed_8),
  'whatsapp_web_sessions',(SELECT count(*) FROM removed_9),
  'pipeline_stages',(SELECT count(*) FROM removed_10),
  'crm_sources',(SELECT count(*) FROM removed_11)
)) AS cleanup_result;
