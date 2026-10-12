drop policy if exists "form-assets authenticated insert" on storage.objects;
create policy "form-assets authenticated insert"
on storage.objects for insert
to authenticated
with check (bucket_id = 'form-assets');

drop policy if exists "form-assets authenticated update" on storage.objects;
create policy "form-assets authenticated update"
on storage.objects for update
to authenticated
using (bucket_id = 'form-assets')
with check (bucket_id = 'form-assets');

drop policy if exists "form-assets authenticated delete" on storage.objects;
create policy "form-assets authenticated delete"
on storage.objects for delete
to authenticated
using (bucket_id = 'form-assets');

drop policy if exists "form-assets authenticated select" on storage.objects;
create policy "form-assets authenticated select"
on storage.objects for select
to authenticated
using (bucket_id = 'form-assets');