-- SideQuest Roblox marketplace schema (Supabase PostgreSQL)
-- No sample/seed rows are created. Only authenticated user submissions appear.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  roblox_username text not null,
  roblox_url text,
  verified boolean not null default false,
  created_at timestamptz not null default now(),
  constraint roblox_username_length check (char_length(roblox_username) between 3 and 20)
);

create table if not exists public.game_listings (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 100),
  description text not null check (char_length(description) between 1 and 5000),
  genre text not null check (genre in ('Obby','Tycoon','Simulator','RPG','FPS','Horror','Other')),
  asset_type text not null check (asset_type in ('rbxl','ownership','system')),
  roblox_url text,
  thumbnail_url text not null,
  accepted_currencies text[] not null check (cardinality(accepted_currencies) > 0 and accepted_currencies <@ array['robux','usd']::text[]),
  price_robux integer check (price_robux is null or price_robux > 0),
  price_usd numeric(10,2) check (price_usd is null or price_usd > 0),
  robux_instructions text,
  stripe_payment_link text,
  status text not null default 'active' check (status in ('active','sold','removed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint currency_price_consistency check (
    ('robux' = any(accepted_currencies)) = (price_robux is not null)
    and ('usd' = any(accepted_currencies)) = (price_usd is not null)
  )
);

create table if not exists public.listing_comments (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.game_listings(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 2000),
  created_at timestamptz not null default now()
);

create table if not exists public.market_orders (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.game_listings(id) on delete restrict,
  buyer_id uuid not null references public.profiles(id) on delete cascade,
  seller_id uuid not null references public.profiles(id) on delete cascade,
  currency text not null check (currency in ('robux','usd')),
  amount numeric(10,2) not null check (amount > 0),
  payment_reference text,
  status text not null default 'pending' check (status in ('pending','paid','cancelled','refunded')),
  created_at timestamptz not null default now(),
  constraint no_self_purchase check (buyer_id <> seller_id)
);

create index if not exists game_listings_feed_idx on public.game_listings(status, created_at desc);
create index if not exists listing_comments_listing_idx on public.listing_comments(listing_id, created_at);
create index if not exists market_orders_buyer_idx on public.market_orders(buyer_id, created_at desc);

alter table public.profiles enable row level security;
alter table public.game_listings enable row level security;
alter table public.listing_comments enable row level security;
alter table public.market_orders enable row level security;

drop policy if exists "Public profiles are readable" on public.profiles;
create policy "Public profiles are readable" on public.profiles for select using (true);
drop policy if exists "Users create own profile" on public.profiles;
create policy "Users create own profile" on public.profiles for insert to authenticated with check (auth.uid() = id);
drop policy if exists "Users update own profile" on public.profiles;
create policy "Users update own profile" on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "Anyone reads active listings" on public.game_listings;
create policy "Anyone reads active listings" on public.game_listings for select using (status = 'active' or auth.uid() = seller_id);
drop policy if exists "Authenticated users create own listings" on public.game_listings;
create policy "Authenticated users create own listings" on public.game_listings for insert to authenticated with check (auth.uid() = seller_id);
drop policy if exists "Sellers update own listings" on public.game_listings;
create policy "Sellers update own listings" on public.game_listings for update to authenticated using (auth.uid() = seller_id) with check (auth.uid() = seller_id);
drop policy if exists "Sellers delete own listings" on public.game_listings;
create policy "Sellers delete own listings" on public.game_listings for delete to authenticated using (auth.uid() = seller_id);

drop policy if exists "Comments readable on active listings" on public.listing_comments;
create policy "Comments readable on active listings" on public.listing_comments for select using (exists(select 1 from public.game_listings l where l.id = listing_id and (l.status = 'active' or l.seller_id = auth.uid())));
drop policy if exists "Signed in users comment as themselves" on public.listing_comments;
create policy "Signed in users comment as themselves" on public.listing_comments for insert to authenticated with check (auth.uid() = user_id and exists(select 1 from public.game_listings l where l.id = listing_id and l.status = 'active'));
drop policy if exists "Authors delete their comments" on public.listing_comments;
create policy "Authors delete their comments" on public.listing_comments for delete to authenticated using (auth.uid() = user_id);

drop policy if exists "Order participants can read orders" on public.market_orders;
create policy "Order participants can read orders" on public.market_orders for select to authenticated using (auth.uid() = buyer_id or auth.uid() = seller_id);
drop policy if exists "Buyers can create own pending orders" on public.market_orders;
create policy "Buyers can create own pending orders" on public.market_orders for insert to authenticated with check (auth.uid() = buyer_id and auth.uid() <> seller_id and status = 'pending' and exists(select 1 from public.game_listings l where l.id = listing_id and l.seller_id = seller_id and l.status = 'active'));

-- Keep profile handles in sync with verified Supabase Auth identities.
create or replace function public.create_marketplace_profile()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles(id, roblox_username)
  values (new.id, coalesce(new.raw_user_meta_data->>'roblox_username', split_part(new.email, '@', 1)))
  on conflict (id) do nothing;
  return new;
end;
$$;
drop trigger if exists create_marketplace_profile on auth.users;
create trigger create_marketplace_profile after insert on auth.users for each row execute procedure public.create_marketplace_profile();

-- Public thumbnails; uploads are restricted to a folder named for the signed-in user ID.
insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values ('roblox-listing-images','roblox-listing-images',true,5242880,array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public=true, file_size_limit=5242880, allowed_mime_types=array['image/jpeg','image/png','image/webp'];
drop policy if exists "Public Roblox listing thumbnails" on storage.objects;
create policy "Public Roblox listing thumbnails" on storage.objects for select using (bucket_id = 'roblox-listing-images');
drop policy if exists "Creators upload their own thumbnails" on storage.objects;
create policy "Creators upload their own thumbnails" on storage.objects for insert to authenticated with check (bucket_id = 'roblox-listing-images' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "Creators update their own thumbnails" on storage.objects;
create policy "Creators update their own thumbnails" on storage.objects for update to authenticated using (bucket_id = 'roblox-listing-images' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "Creators remove their own thumbnails" on storage.objects;
create policy "Creators remove their own thumbnails" on storage.objects for delete to authenticated using (bucket_id = 'roblox-listing-images' and (storage.foldername(name))[1] = auth.uid()::text);

-- Realtime comments/listings: enable public-table changes if not already enabled.
alter publication supabase_realtime add table public.game_listings;
alter publication supabase_realtime add table public.listing_comments;
