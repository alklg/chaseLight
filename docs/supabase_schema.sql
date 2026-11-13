-- 追光 · Supabase 建表脚本
-- 用法：Supabase 控制台 → 左侧 SQL Editor → 新建 query → 全选粘贴 → Run
-- 只需跑一次。三张表 + 三条权限策略，重复跑会报「已存在」，可以忽略。

-- ---------------------------------------------------------------
-- 1. 用户资料
-- ---------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users on delete cascade,
  nickname text,
  color int default 0,
  signature text,
  gender int default 0,
  cover text,
  created_at timestamptz default now()
);

-- 已有库补列（新库可忽略）
alter table public.profiles add column if not exists signature text;
alter table public.profiles add column if not exists gender int default 0;
-- 封面图（头像列本来就有）
alter table public.profiles add column if not exists cover text;

-- ---------------------------------------------------------------
-- 2. 收藏（对应 App 里的星标）
-- ---------------------------------------------------------------
create table if not exists public.favorites (
  id bigserial primary key,
  user_id uuid not null references auth.users on delete cascade,
  source_id text not null,
  title text not null,
  detail_url text not null,
  source_name text,
  cover text,
  kind text default 'video',
  created_at timestamptz default now(),
  -- 同一个账号下，同一个源里的同一个条目只留一条
  unique (user_id, source_id, detail_url)
);

-- ---------------------------------------------------------------
-- 3. 阅读 / 观看进度
-- ---------------------------------------------------------------
create table if not exists public.progress (
  id bigserial primary key,
  user_id uuid not null references auth.users on delete cascade,
  source_id text not null,
  detail_url text not null,
  title text,
  cover text,
  kind text default 'video',
  total_episodes int default 0,
  chapter_index int default 0,
  episode_name text,
  episode_url text,
  updated_at timestamptz default now(),
  unique (user_id, source_id, detail_url)
);

-- ---------------------------------------------------------------
-- 4. 行级安全：每个人只能读写自己的数据
--    enable 之后不加 policy 的话，连自己都读不到，所以必须成对出现
-- ---------------------------------------------------------------
alter table public.profiles  enable row level security;
alter table public.favorites enable row level security;
alter table public.progress  enable row level security;

drop policy if exists "own profile" on public.profiles;
create policy "own profile" on public.profiles
  for all
  using (auth.uid() = id)
  with check (auth.uid() = id);

drop policy if exists "own favorites" on public.favorites;
create policy "own favorites" on public.favorites
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "own progress" on public.progress;
create policy "own progress" on public.progress
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------
-- 5. 索引：按用户查是最主要的读法
-- ---------------------------------------------------------------
create index if not exists favorites_user_idx on public.favorites (user_id, created_at desc);
create index if not exists progress_user_idx  on public.progress  (user_id, updated_at desc);

-- ---------------------------------------------------------------
-- 6. 迁移：后续追加的字段（可重复执行）
--    交友模块需要的资料字段
-- ---------------------------------------------------------------
alter table public.profiles
  add column if not exists email     text,
  add column if not exists gender    int  default 0,
  add column if not exists birthday  date,
  add column if not exists avatar    text,
  add column if not exists signature text;

-- gender 只允许这几个值：0 未设置 / 1 男 / 2 女 / 3 不愿透露
alter table public.profiles
  drop constraint if exists profiles_gender_check;
alter table public.profiles
  add constraint profiles_gender_check check (gender in (0, 1, 2, 3));

-- ---------------------------------------------------------------
-- 6. Storage：头像 / 背景图
--    两个公开桶，读公开；写只允许本人 uid 目录
--    桶已在 Dashboard 建过也没关系，这段只补策略
-- ---------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true),
       ('backgrounds', 'backgrounds', true)
on conflict (id) do update set public = true;

drop policy if exists "profile image read" on storage.objects;
create policy "profile image read" on storage.objects
  for select using (bucket_id in ('avatars', 'backgrounds'));

drop policy if exists "profile image insert" on storage.objects;
create policy "profile image insert" on storage.objects
  for insert to authenticated
  with check (
    bucket_id in ('avatars', 'backgrounds')
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "profile image update" on storage.objects;
create policy "profile image update" on storage.objects
  for update to authenticated
  using (
    bucket_id in ('avatars', 'backgrounds')
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id in ('avatars', 'backgrounds')
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "profile image delete" on storage.objects;
create policy "profile image delete" on storage.objects
  for delete to authenticated
  using (
    bucket_id in ('avatars', 'backgrounds')
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ---------------------------------------------------------------
-- 7. 壁纸商店
--    文件放 Storage 的 wallpapers 桶，表里只存路径和元信息
-- ---------------------------------------------------------------
create table if not exists public.wallpapers (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  author_id uuid references auth.users on delete set null,
  storage_path text not null,
  thumb_path text,
  tint int,
  tags text[] default '{}',
  status text not null default 'published',
  downloads int not null default 0,
  created_at timestamptz default now()
);

alter table public.wallpapers enable row level security;

drop policy if exists "wallpapers read" on public.wallpapers;
create policy "wallpapers read" on public.wallpapers
  for select using (status = 'published' or author_id = auth.uid());

-- 商店只读：用户不能上传/修改，壁纸由后台（service role / Dashboard）维护
drop policy if exists "wallpapers insert" on public.wallpapers;
drop policy if exists "wallpapers update" on public.wallpapers;

create index if not exists wallpapers_published_idx
  on public.wallpapers (status, created_at desc);

insert into storage.buckets (id, name, public)
values ('wallpapers', 'wallpapers', true)
on conflict (id) do update set public = true;

drop policy if exists "wallpaper file write" on storage.objects;
create policy "wallpaper file write" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'wallpapers');

drop policy if exists "wallpaper file read" on storage.objects;
create policy "wallpaper file read" on storage.objects
  for select using (bucket_id = 'wallpapers');
