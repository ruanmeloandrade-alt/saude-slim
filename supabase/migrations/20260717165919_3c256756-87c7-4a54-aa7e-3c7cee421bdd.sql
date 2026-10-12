
CREATE POLICY "company-logos read own workspace"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'company-logos'
    AND public.is_workspace_member((split_part(name, '/', 1))::uuid, auth.uid())
  );

CREATE POLICY "company-logos write own workspace"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'company-logos'
    AND public.is_workspace_member((split_part(name, '/', 1))::uuid, auth.uid())
  );

CREATE POLICY "company-logos update own workspace"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'company-logos'
    AND public.is_workspace_member((split_part(name, '/', 1))::uuid, auth.uid())
  );

CREATE POLICY "company-logos delete own workspace"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'company-logos'
    AND public.is_workspace_member((split_part(name, '/', 1))::uuid, auth.uid())
  );
