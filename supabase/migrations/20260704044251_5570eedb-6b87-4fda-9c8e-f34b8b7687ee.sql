
-- RLS para o bucket meta-creatives (privado, organizado por workspace_id no primeiro folder)
CREATE POLICY "Members can view own workspace creatives"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'meta-creatives'
    AND public.is_workspace_member((storage.foldername(name))[1]::uuid, auth.uid())
  );

CREATE POLICY "Members can upload own workspace creatives"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'meta-creatives'
    AND public.is_workspace_member((storage.foldername(name))[1]::uuid, auth.uid())
  );

CREATE POLICY "Members can update own workspace creatives"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'meta-creatives'
    AND public.is_workspace_member((storage.foldername(name))[1]::uuid, auth.uid())
  );

CREATE POLICY "Members can delete own workspace creatives"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'meta-creatives'
    AND public.is_workspace_member((storage.foldername(name))[1]::uuid, auth.uid())
  );
