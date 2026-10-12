
DROP POLICY IF EXISTS "coupons read auth" ON public.coupons;
CREATE POLICY "coupons read active or admin"
  ON public.coupons FOR SELECT TO authenticated
  USING (
    public.has_role(auth.uid(), 'super_admin')
    OR (
      is_active = true
      AND (starts_at IS NULL OR starts_at <= now())
      AND (expires_at IS NULL OR expires_at > now())
    )
  );

DROP POLICY IF EXISTS "crm_forms public read by slug" ON public.crm_forms;
REVOKE SELECT ON public.crm_forms FROM anon;

DROP POLICY IF EXISTS "form-assets authenticated insert" ON storage.objects;
DROP POLICY IF EXISTS "form-assets authenticated update" ON storage.objects;
DROP POLICY IF EXISTS "form-assets authenticated delete" ON storage.objects;
DROP POLICY IF EXISTS "form-assets authenticated select" ON storage.objects;

CREATE POLICY "form-assets workspace select"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'form-assets'
    AND (storage.foldername(name))[1]::uuid IN (
      SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "form-assets workspace insert"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'form-assets'
    AND (storage.foldername(name))[1]::uuid IN (
      SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "form-assets workspace update"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'form-assets'
    AND (storage.foldername(name))[1]::uuid IN (
      SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    bucket_id = 'form-assets'
    AND (storage.foldername(name))[1]::uuid IN (
      SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "form-assets workspace delete"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'form-assets'
    AND (storage.foldername(name))[1]::uuid IN (
      SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "inbox_outgoing_authenticated_read" ON storage.objects;
DROP POLICY IF EXISTS "inbox_outgoing_authenticated_insert" ON storage.objects;

CREATE POLICY "inbox_outgoing workspace select"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'inbox-outgoing'
    AND (storage.foldername(name))[1]::uuid IN (
      SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "inbox_outgoing workspace insert"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'inbox-outgoing'
    AND (storage.foldername(name))[1]::uuid IN (
      SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "inbox_outgoing workspace update"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'inbox-outgoing'
    AND (storage.foldername(name))[1]::uuid IN (
      SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    bucket_id = 'inbox-outgoing'
    AND (storage.foldername(name))[1]::uuid IN (
      SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "inbox_outgoing workspace delete"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'inbox-outgoing'
    AND (storage.foldername(name))[1]::uuid IN (
      SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid()
    )
  );
