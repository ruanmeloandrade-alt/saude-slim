
-- Autenticados podem ler/inserir dentro de inbox-outgoing (o servidor sempre organiza por workspace_id/leadId)
CREATE POLICY "inbox_outgoing_authenticated_read"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'inbox-outgoing');

CREATE POLICY "inbox_outgoing_authenticated_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'inbox-outgoing');
