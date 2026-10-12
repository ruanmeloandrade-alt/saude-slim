ALTER TABLE public.coupons
  ADD COLUMN IF NOT EXISTS name text,
  ADD COLUMN IF NOT EXISTS description text,
  ADD COLUMN IF NOT EXISTS created_by uuid;

UPDATE public.coupons
SET name = code
WHERE name IS NULL;

ALTER TABLE public.coupons
  ALTER COLUMN name SET DEFAULT '',
  ALTER COLUMN name SET NOT NULL;

CREATE TABLE IF NOT EXISTS public.internal_campaigns (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  type text NOT NULL CHECK (type IN ('billing', 'sms', 'renewal', 'promotional', 'recovery')),
  name text NOT NULL,
  audience text NOT NULL DEFAULT '',
  trigger_key text,
  message text NOT NULL DEFAULT '',
  action text NOT NULL DEFAULT '',
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'active', 'paused', 'sent', 'archived')),
  scheduled_at timestamptz,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.internal_campaigns TO authenticated;
GRANT ALL ON public.internal_campaigns TO service_role;
ALTER TABLE public.internal_campaigns ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "super admins manage internal campaigns" ON public.internal_campaigns;
CREATE POLICY "super admins manage internal campaigns"
ON public.internal_campaigns
FOR ALL
TO authenticated
USING (public.has_role(auth.uid(), 'super_admin'))
WITH CHECK (public.has_role(auth.uid(), 'super_admin'));

CREATE TABLE IF NOT EXISTS public.internal_campaign_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id uuid REFERENCES public.internal_campaigns(id) ON DELETE SET NULL,
  coupon_id uuid REFERENCES public.coupons(id) ON DELETE SET NULL,
  action_type text NOT NULL,
  title text NOT NULL,
  details jsonb NOT NULL DEFAULT '{}'::jsonb,
  result text NOT NULL DEFAULT 'registered',
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.internal_campaign_history TO authenticated;
GRANT ALL ON public.internal_campaign_history TO service_role;
ALTER TABLE public.internal_campaign_history ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "super admins manage internal campaign history" ON public.internal_campaign_history;
CREATE POLICY "super admins manage internal campaign history"
ON public.internal_campaign_history
FOR ALL
TO authenticated
USING (public.has_role(auth.uid(), 'super_admin'))
WITH CHECK (public.has_role(auth.uid(), 'super_admin'));

DROP TRIGGER IF EXISTS touch_internal_campaigns_updated_at ON public.internal_campaigns;
CREATE TRIGGER touch_internal_campaigns_updated_at
BEFORE UPDATE ON public.internal_campaigns
FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();