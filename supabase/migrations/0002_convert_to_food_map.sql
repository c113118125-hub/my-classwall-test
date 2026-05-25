-- 校園美食地圖 schema
-- 將 ClassWall 轉換成美食推薦系統

-- 1. 移除舊表（備份資料後）
drop table if exists public.answers cascade;
drop table if exists public.questions cascade;

-- 2. restaurants 表：美食點資訊
create table if not exists public.restaurants (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 100),
  location text not null check (char_length(location) between 1 and 200),
  category text not null check (category in ('早餐', '午餐', '晚餐', '甜點', '咖啡', '飲料', '其他')),
  likes integer not null default 0 check (likes >= 0),
  created_at timestamptz not null default now()
);

create index if not exists restaurants_likes_created_idx
  on public.restaurants (likes desc, created_at desc);

create index if not exists restaurants_category_idx
  on public.restaurants (category);

-- 3. reviews 表：美食評論（一對多：一間餐廳有多筆評論）
create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants (id) on delete cascade,
  content text not null check (char_length(content) between 1 and 500),
  created_at timestamptz not null default now()
);

create index if not exists reviews_restaurant_id_idx
  on public.reviews (restaurant_id);

-- 4. 開啟 Realtime
alter publication supabase_realtime add table public.restaurants;
alter publication supabase_realtime add table public.reviews;

-- 5. RLS：匿名使用者可讀、可新增、可按讚
alter table public.restaurants enable row level security;
alter table public.reviews enable row level security;

drop policy if exists "anyone can read restaurants" on public.restaurants;
create policy "anyone can read restaurants"
  on public.restaurants for select
  using (true);

drop policy if exists "anyone can insert restaurants" on public.restaurants;
create policy "anyone can insert restaurants"
  on public.restaurants for insert
  with check (true);

drop policy if exists "anyone can like restaurants" on public.restaurants;
create policy "anyone can like restaurants"
  on public.restaurants for update
  using (true)
  with check (true);

drop policy if exists "anyone can read reviews" on public.reviews;
create policy "anyone can read reviews"
  on public.reviews for select
  using (true);

drop policy if exists "anyone can insert reviews" on public.reviews;
create policy "anyone can insert reviews"
  on public.reviews for insert
  with check (true);

-- 6. seed：示範美食點
insert into public.restaurants (name, location, category, likes)
values
  ('食堂一號', '宿舍旁', '午餐', 5),
  ('甜蜜咖啡', '圖書館一樓', '咖啡', 3),
  ('小王水餃', '校門口', '早餐', 8)
on conflict do nothing;
