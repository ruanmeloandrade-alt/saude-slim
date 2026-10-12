CREATE POLICY "employee_of_month_select_members"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'employee-of-month');

CREATE POLICY "employee_of_month_upload_managers"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'employee-of-month'
  AND EXISTS (
    SELECT 1 FROM public.workspaces w
    JOIN public.profiles p ON p.current_workspace_id = w.id
    WHERE p.id = auth.uid()
      AND public.can_manage_workflow(w.id, auth.uid())
  )
);

CREATE POLICY "employee_of_month_delete_managers"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'employee-of-month'
  AND EXISTS (
    SELECT 1 FROM public.workspaces w
    JOIN public.profiles p ON p.current_workspace_id = w.id
    WHERE p.id = auth.uid()
      AND public.can_manage_workflow(w.id, auth.uid())
  )
);