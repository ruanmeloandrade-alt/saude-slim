-- Social Media durable media storage.
-- Keeps generated images, brand logos and references scoped by workspace.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'social-media',
  'social-media',
  false,
  20971520,
  array['image/png','image/jpeg','image/webp','image/svg+xml','video/mp4','video/quicktime','application/pdf']
)
on conflict (id) do update
set file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects'
      and policyname = 'social_media_workspace_select'
  ) then
    create policy social_media_workspace_select
      on storage.objects for select to authenticated
      using (
        bucket_id = 'social-media'
        and exists (
          select 1 from public.workspaces w
          where w.id::text = (storage.foldername(name))[1]
            and (w.owner_id = auth.uid() or exists (
              select 1 from public.workspace_members wm
              where wm.workspace_id = w.id and wm.user_id = auth.uid()
            ))
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects'
      and policyname = 'social_media_workspace_insert'
  ) then
    create policy social_media_workspace_insert
      on storage.objects for insert to authenticated
      with check (
        bucket_id = 'social-media'
        and exists (
          select 1 from public.workspaces w
          where w.id::text = (storage.foldername(name))[1]
            and (w.owner_id = auth.uid() or exists (
              select 1 from public.workspace_members wm
              where wm.workspace_id = w.id and wm.user_id = auth.uid()
            ))
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects'
      and policyname = 'social_media_workspace_update'
  ) then
    create policy social_media_workspace_update
      on storage.objects for update to authenticated
      using (
        bucket_id = 'social-media'
        and exists (
          select 1 from public.workspaces w
          where w.id::text = (storage.foldername(name))[1]
            and (w.owner_id = auth.uid() or exists (
              select 1 from public.workspace_members wm
              where wm.workspace_id = w.id and wm.user_id = auth.uid()
            ))
        )
      )
      with check (
        bucket_id = 'social-media'
        and exists (
          select 1 from public.workspaces w
          where w.id::text = (storage.foldername(name))[1]
            and (w.owner_id = auth.uid() or exists (
              select 1 from public.workspace_members wm
              where wm.workspace_id = w.id and wm.user_id = auth.uid()
            ))
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects'
      and policyname = 'social_media_workspace_delete'
  ) then
    create policy social_media_workspace_delete
      on storage.objects for delete to authenticated
      using (
        bucket_id = 'social-media'
        and exists (
          select 1 from public.workspaces w
          where w.id::text = (storage.foldername(name))[1]
            and (w.owner_id = auth.uid() or exists (
              select 1 from public.workspace_members wm
              where wm.workspace_id = w.id and wm.user_id = auth.uid()
            ))
        )
      );
  end if;
end $$;
