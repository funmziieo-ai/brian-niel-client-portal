-- Brian Niel Construction — Client Portal
-- Run this in Supabase: Project > SQL Editor > New query > paste > Run

-- 1. Projects (one row per homeowner build)
create table projects (
  id uuid primary key default gen_random_uuid(),
  name text not null,                    -- "Highland Estate"
  address text not null,
  pm_name text not null,                 -- assigned Project Manager
  original_budget numeric not null default 0,
  running_total numeric not null default 0,
  percent_complete int not null default 0,
  created_at timestamptz default now()
);

-- 2. Homeowner profiles — one login per project, linked to Supabase Auth
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  address text not null,
  date_of_birth date,
  project_id uuid references projects(id) not null,
  created_at timestamptz default now()
);

-- 3. Milestone timeline (Foundation -> Framing -> Roofing -> Finishes)
create table milestones (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id) not null,
  name text not null,
  sort_order int not null,
  status text not null default 'pending', -- pending | active | done
  completed_on date
);

-- 4. Daily field log entries
create table field_logs (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id) not null,
  phase text not null,
  note text not null,
  photo_url text,
  pm_name text not null,
  created_at timestamptz default now()
);

-- 5. Change orders (needs both homeowner + PM sign-off)
create table change_orders (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id) not null,
  title text not null,
  description text,
  amount numeric not null,
  homeowner_approved boolean not null default false,
  pm_approved boolean not null default false,
  created_at timestamptz default now()
);

-- 6. Documents (Blueprints / Material Selections / Contracts)
create table documents (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id) not null,
  folder text not null,
  file_name text not null,
  file_url text not null,
  uploaded_at timestamptz default now()
);

-- 7. Messages (homeowner <-> PM chat)
create table messages (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id) not null,
  sender text not null,          -- 'homeowner' | 'pm'
  body text not null,
  attachment_url text,
  created_at timestamptz default now()
);

-- ---------- Row Level Security ----------
-- Every table is locked down so a homeowner can only ever see rows
-- belonging to their own project_id (looked up from their profile row).

alter table profiles enable row level security;
alter table milestones enable row level security;
alter table field_logs enable row level security;
alter table change_orders enable row level security;
alter table documents enable row level security;
alter table messages enable row level security;

create policy "own profile" on profiles
  for select using (auth.uid() = id);

create policy "own project milestones" on milestones
  for select using (
    project_id in (select project_id from profiles where id = auth.uid())
  );

create policy "own project field logs" on field_logs
  for select using (
    project_id in (select project_id from profiles where id = auth.uid())
  );

create policy "own project change orders" on change_orders
  for select using (
    project_id in (select project_id from profiles where id = auth.uid())
  );

create policy "own project documents" on documents
  for select using (
    project_id in (select project_id from profiles where id = auth.uid())
  );

create policy "own project messages" on messages
  for select using (
    project_id in (select project_id from profiles where id = auth.uid())
  );

-- A homeowner can send messages and approve their own change orders:
create policy "send own messages" on messages
  for insert with check (
    project_id in (select project_id from profiles where id = auth.uid())
  );

create policy "approve own change orders" on change_orders
  for update using (
    project_id in (select project_id from profiles where id = auth.uid())
  );
