
CREATE POLICY "social-media members read"
ON storage.objects FOR SELECT TO authenticated
USING (
  bucket_id = 'social-media'
  AND public.is_workspace_member((storage.foldername(name))[1]::uuid, auth.uid())
);
CREATE POLICY "social-media members insert"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'social-media'
  AND public.is_workspace_member((storage.foldername(name))[1]::uuid, auth.uid())
);
CREATE POLICY "social-media members update"
ON storage.objects FOR UPDATE TO authenticated
USING (
  bucket_id = 'social-media'
  AND public.is_workspace_member((storage.foldername(name))[1]::uuid, auth.uid())
);
CREATE POLICY "social-media members delete"
ON storage.objects FOR DELETE TO authenticated
USING (
  bucket_id = 'social-media'
  AND public.is_workspace_member((storage.foldername(name))[1]::uuid, auth.uid())
);
