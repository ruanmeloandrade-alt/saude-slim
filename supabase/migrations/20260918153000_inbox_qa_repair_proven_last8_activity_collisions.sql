-- QA Inbox WhatsApp 2026-09-18
-- Repair only historical lead_activity links that are provably attributable to the
-- legacy "last 8 digits" matcher:
--   1) activity has a WhatsApp message id;
--   2) the authoritative stored message resolves to a direct @s.whatsapp.net JID;
--   3) current lead phone differs from that JID but shares exactly the last 8 digits;
--   4) exactly one different lead in the same workspace has the full exact JID digits.
--
-- Ambiguous mismatches are deliberately left untouched for manual review.
-- The update is idempotent: after lead_id is corrected, the source mismatch predicate
-- no longer matches.

with linked as (
  select
    a.id as activity_id,
    a.workspace_id,
    a.lead_id as old_lead_id,
    regexp_replace(coalesce(l.phone_normalized, l.phone, ''), '\D', '', 'g') as old_digits,
    regexp_replace(split_part(coalesce(m.remote_jid, ''), '@', 1), '\D', '', 'g') as jid_digits,
    m.remote_jid,
    m.session_id
  from public.lead_activities a
  join public.leads l
    on l.id = a.lead_id
   and l.workspace_id = a.workspace_id
  join public.whatsapp_web_messages m
    on m.workspace_id = a.workspace_id
   and m.message_id = a.payload ->> 'whatsapp_message_id'
  where a.type in ('message_in', 'message_out')
    and m.remote_jid like '%@s.whatsapp.net'
),
candidate_targets as (
  select
    x.activity_id,
    x.workspace_id,
    x.old_lead_id,
    min(target.id::text)::uuid as target_lead_id,
    max(x.remote_jid) as remote_jid,
    min(x.session_id::text)::uuid as session_id
  from linked x
  join public.leads target
    on target.workspace_id = x.workspace_id
   and target.id <> x.old_lead_id
   and regexp_replace(coalesce(target.phone_normalized, target.phone, ''), '\D', '', 'g')
       = x.jid_digits
  where length(x.old_digits) >= 8
    and length(x.jid_digits) >= 8
    and x.old_digits <> x.jid_digits
    and right(x.old_digits, 8) = right(x.jid_digits, 8)
  group by x.activity_id, x.workspace_id, x.old_lead_id
  having count(distinct target.id) = 1
)
update public.lead_activities a
set
  lead_id = c.target_lead_id,
  payload = coalesce(a.payload, '{}'::jsonb)
    || jsonb_build_object(
      'whatsapp_session_id', c.session_id,
      'whatsapp_remote_jid', c.remote_jid,
      'whatsapp_source_jid', c.remote_jid,
      'whatsapp_conversation_key', c.session_id::text || ':' || lower(c.remote_jid),
      'whatsapp_identity_repaired_at', now(),
      'whatsapp_identity_repair', 'qa_last8_exact_target'
    )
from candidate_targets c
where a.id = c.activity_id
  and a.workspace_id = c.workspace_id
  and a.lead_id = c.old_lead_id;
