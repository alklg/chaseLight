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
  created_at timestamptz default now()
);

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
