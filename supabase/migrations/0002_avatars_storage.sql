-- Avatar storage: a public bucket for profile photos.
--
-- "Public" only affects READS — anyone with the URL can view an avatar (low
-- sensitivity, and the filename is randomised by the app so URLs aren't
-- guessable). WRITES stay owner-only via the policies below: a user may only
-- touch files under a folder named after their own auth.uid().
--
-- Files are stored at: avatars/<user_id>/<random>.<ext>

-- 1. Create the public bucket (id == name == 'avatars'). Idempotent.
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = true;

-- 2. Anyone can read avatar files (matches the public bucket / public URLs).
create policy "Avatar images are publicly readable"
  on storage.objects for select
  using (bucket_id = 'avatars');

-- 3. A signed-in user may upload only into their own folder.
create policy "Users can upload their own avatar"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- 4. ...and update only their own files (upsert overwrites count as updates).
create policy "Users can update their own avatar"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- 5. ...and delete only their own files (the app prunes old avatars on upload).
create policy "Users can delete their own avatar"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
