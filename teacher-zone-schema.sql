-- AHHS Teacher Zone + Teacher Profiles migration
-- Safe to run more than once.
create extension if not exists pgcrypto;

create table if not exists public.teacher_profiles (
 id uuid primary key default gen_random_uuid(),
 teacher_id uuid not null unique,
 name text not null,
 subject text,
 designation text default 'Teacher',
 branch text,
 shift text,
 employee_id text,
 phone text,
 email text,
 qualification text,
 joining_date date,
 gender text,
 address text,
 bio text,
 photo_url text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);

alter table public.teacher_profiles add column if not exists teacher_id uuid;
alter table public.teacher_profiles add column if not exists name text;
alter table public.teacher_profiles add column if not exists subject text;
alter table public.teacher_profiles add column if not exists designation text default 'Teacher';
alter table public.teacher_profiles add column if not exists branch text;
alter table public.teacher_profiles add column if not exists shift text;
alter table public.teacher_profiles add column if not exists employee_id text;
alter table public.teacher_profiles add column if not exists phone text;
alter table public.teacher_profiles add column if not exists email text;
alter table public.teacher_profiles add column if not exists qualification text;
alter table public.teacher_profiles add column if not exists joining_date date;
alter table public.teacher_profiles add column if not exists gender text;
alter table public.teacher_profiles add column if not exists address text;
alter table public.teacher_profiles add column if not exists bio text;
alter table public.teacher_profiles add column if not exists photo_url text;
alter table public.teacher_profiles add column if not exists created_at timestamptz default now();
alter table public.teacher_profiles add column if not exists updated_at timestamptz default now();

-- Existing functional tables from the previous Teacher Zone.
create table if not exists public.teacher_attendance (
 id uuid primary key default gen_random_uuid(), teacher_id uuid not null, attendance_date date not null,
 class_name text not null, section text, student_id text not null, student_name text not null,
 status text not null default 'present', remarks text, created_at timestamptz not null default now()
);
create table if not exists public.teacher_marks (
 id uuid primary key default gen_random_uuid(), teacher_id uuid not null, exam_name text not null,
 mark_date date, class_name text not null, section text, subject text not null, student_id text not null,
 student_name text not null, marks numeric not null, full_marks numeric not null default 100,
 remarks text, created_at timestamptz not null default now()
);
create table if not exists public.teacher_assignments (
 id uuid primary key default gen_random_uuid(), teacher_id uuid not null, title text not null,
 subject text not null, class_name text not null, section text, due_date date, description text,
 created_at timestamptz not null default now()
);
create table if not exists public.teacher_materials (
 id uuid primary key default gen_random_uuid(), teacher_id uuid not null, title text not null,
 subject text not null, class_name text, section text, resource_url text, description text,
 created_at timestamptz not null default now()
);
create table if not exists public.teacher_leave_requests (
 id uuid primary key default gen_random_uuid(), teacher_id uuid not null, from_date date not null,
 to_date date not null, reason text not null, status text not null default 'pending',
 created_at timestamptz not null default now()
);

-- Public image bucket for teacher profile pictures.
insert into storage.buckets (id,name,public)
values ('teacher-profiles','teacher-profiles',true)
on conflict (id) do update set public=true;

-- RLS on profile + work tables.
alter table public.teacher_profiles enable row level security;
alter table public.teacher_attendance enable row level security;
alter table public.teacher_marks enable row level security;
alter table public.teacher_assignments enable row level security;
alter table public.teacher_materials enable row level security;
alter table public.teacher_leave_requests enable row level security;

do $$declare t text; begin
 foreach t in array array['teacher_profiles','teacher_attendance','teacher_marks','teacher_assignments','teacher_materials','teacher_leave_requests'] loop
  execute format('drop policy if exists "tz_select" on public.%I',t);
  execute format('drop policy if exists "tz_insert" on public.%I',t);
  execute format('drop policy if exists "tz_update" on public.%I',t);
  execute format('drop policy if exists "tz_delete" on public.%I',t);
  execute format('create policy "tz_select" on public.%I for select using ((public.get_my_role() = ''teacher'' and auth.uid() = teacher_id) or public.get_my_role() = ''admin'')',t);
  execute format('create policy "tz_insert" on public.%I for insert with check ((public.get_my_role() = ''teacher'' and auth.uid() = teacher_id) or public.get_my_role() = ''admin'')',t);
  execute format('create policy "tz_update" on public.%I for update using ((public.get_my_role() = ''teacher'' and auth.uid() = teacher_id) or public.get_my_role() = ''admin'') with check ((public.get_my_role() = ''teacher'' and auth.uid() = teacher_id) or public.get_my_role() = ''admin'')',t);
  execute format('create policy "tz_delete" on public.%I for delete using ((public.get_my_role() = ''teacher'' and auth.uid() = teacher_id) or public.get_my_role() = ''admin'')',t);
 end loop;
end$$;

-- Storage: teachers may manage their own folder; admins may manage all teacher profile images.
drop policy if exists "teacher_profile_images_insert" on storage.objects;
drop policy if exists "teacher_profile_images_update" on storage.objects;
drop policy if exists "teacher_profile_images_delete" on storage.objects;
drop policy if exists "teacher_profile_images_select" on storage.objects;
create policy "teacher_profile_images_select" on storage.objects for select using (bucket_id='teacher-profiles');
create policy "teacher_profile_images_insert" on storage.objects for insert with check (
 bucket_id='teacher-profiles' and ((public.get_my_role()='teacher' and (storage.foldername(name))[1]=auth.uid()::text) or public.get_my_role()='admin')
);
create policy "teacher_profile_images_update" on storage.objects for update using (
 bucket_id='teacher-profiles' and ((public.get_my_role()='teacher' and (storage.foldername(name))[1]=auth.uid()::text) or public.get_my_role()='admin')
) with check (bucket_id='teacher-profiles');
create policy "teacher_profile_images_delete" on storage.objects for delete using (
 bucket_id='teacher-profiles' and ((public.get_my_role()='teacher' and (storage.foldername(name))[1]=auth.uid()::text) or public.get_my_role()='admin')
);

-- Optional starter profile for the newly added teacher. Replace TEACHER_USER_UUID if a real Auth UUID is available.
-- insert into public.teacher_profiles (teacher_id,name,subject,designation,shift,photo_url)
-- values ('TEACHER_USER_UUID','MAKSUDUL HAQUE','Accounting','Teacher','Day',null)
-- on conflict (teacher_id) do update set name=excluded.name,subject=excluded.subject,designation=excluded.designation,shift=excluded.shift;
