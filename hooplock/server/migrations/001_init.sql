-- HoopLock initial schema
create extension if not exists pgcrypto;

create table merchants (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  owner_name    text not null default '',
  phone         text not null default '',
  city          text not null default '',
  address       text not null default '',
  -- Numbers a locked phone may still call (shop owner, shop landline). Emergency numbers are always allowed.
  call_numbers  text[] not null default '{}',
  upi_id        text not null default '',
  android_keys  integer not null default 0 check (android_keys >= 0),
  ios_keys      integer not null default 0 check (ios_keys >= 0),
  settings      jsonb not null default '{}',
  active        boolean not null default true,
  created_at    timestamptz not null default now()
);

create table users (
  id            uuid primary key default gen_random_uuid(),
  merchant_id   uuid references merchants(id),
  role          text not null check (role in ('super_admin','owner','staff')),
  name          text not null,
  phone         text not null unique,
  password_hash text not null,
  active        boolean not null default true,
  created_at    timestamptz not null default now(),
  check ((role = 'super_admin') = (merchant_id is null))
);

create table key_ledger (
  id           bigserial primary key,
  merchant_id  uuid not null references merchants(id),
  platform     text not null check (platform in ('android','ios')),
  delta        integer not null,
  reason       text not null,
  device_id    uuid,
  created_by   uuid references users(id),
  created_at   timestamptz not null default now()
);

create table customers (
  id           uuid primary key default gen_random_uuid(),
  merchant_id  uuid not null references merchants(id),
  name         text not null,
  mobile       text not null,
  alt_mobile   text not null default '',
  address      text not null default '',
  id_type      text not null default '',
  id_last4     text not null default '',
  notes        text not null default '',
  photo        bytea,
  photo_type   text,
  created_at   timestamptz not null default now()
);
create index customers_merchant on customers(merchant_id, created_at desc);

create table devices (
  id              uuid primary key default gen_random_uuid(),
  merchant_id     uuid not null references merchants(id),
  customer_id     uuid not null references customers(id),
  platform        text not null check (platform in ('android','ios')),
  -- pending: sale created, phone not enrolled yet; active: enrolled and managed;
  -- released: loan closed and phone freed; removed: agent gone (uninstalled / lost)
  status          text not null default 'pending' check (status in ('pending','active','released','removed')),
  -- desired state the phone must converge to
  lock_state      text not null default 'unlocked' check (lock_state in ('unlocked','warning','restricted','locked')),
  lock_reason     text not null default '',
  lock_message    text not null default '',
  state_seq       integer not null default 1,
  -- what the phone last reported
  reported_state  text,
  imei1           text not null default '',
  imei2           text not null default '',
  serial          text not null default '',
  brand           text not null default '',
  model           text not null default '',
  os_version      text not null default '',
  agent_version   text not null default '',
  sim1_number     text not null default '',
  sim1_operator   text not null default '',
  sim2_number     text not null default '',
  sim2_operator   text not null default '',
  battery         integer,
  fcm_token       text,
  api_token_hash  text,
  command_key     text,
  locate_requested boolean not null default false,
  last_seen_at    timestamptz,
  enrolled_at     timestamptz,
  released_at     timestamptz,
  created_at      timestamptz not null default now()
);
create index devices_merchant on devices(merchant_id, created_at desc);
create index devices_imei on devices(imei1);

create table loans (
  id             uuid primary key default gen_random_uuid(),
  device_id      uuid not null unique references devices(id),
  merchant_id    uuid not null references merchants(id),
  total_amount   numeric(12,2) not null,
  down_payment   numeric(12,2) not null default 0,
  emi_amount     numeric(12,2) not null,
  emi_count      integer not null check (emi_count between 1 and 60),
  first_emi_date date not null,
  loan_ref       text not null default '',
  notes          text not null default '',
  status         text not null default 'open' check (status in ('open','closed')),
  consent_at     timestamptz,
  created_at     timestamptz not null default now()
);

create table instalments (
  id          uuid primary key default gen_random_uuid(),
  loan_id     uuid not null references loans(id) on delete cascade,
  seq         integer not null,
  due_date    date not null,
  amount      numeric(12,2) not null,
  paid_amount numeric(12,2) not null default 0,
  paid_at     timestamptz,
  method      text,
  ref         text,
  recorded_by uuid references users(id),
  unique (loan_id, seq)
);
create index instalments_due on instalments(due_date) where paid_at is null;

create table enrollment_tokens (
  token       text primary key,
  merchant_id uuid not null references merchants(id),
  device_id   uuid not null references devices(id),
  expires_at  timestamptz not null,
  used_at     timestamptz
);

create table locations (
  id         bigserial primary key,
  device_id  uuid not null references devices(id),
  lat        double precision not null,
  lng        double precision not null,
  accuracy   real,
  reason     text not null default '',
  created_at timestamptz not null default now()
);
create index locations_device on locations(device_id, created_at desc);

create table device_events (
  id         bigserial primary key,
  device_id  uuid not null references devices(id),
  type       text not null,
  data       jsonb not null default '{}',
  created_at timestamptz not null default now()
);
create index device_events_device on device_events(device_id, created_at desc);

create table reminders (
  id         bigserial primary key,
  device_id  uuid not null references devices(id),
  kind       text not null,
  channel    text not null,
  message    text not null,
  status     text not null,
  created_at timestamptz not null default now()
);
create index reminders_device on reminders(device_id, created_at desc);

create table audit_log (
  id          bigserial primary key,
  merchant_id uuid,
  user_id     uuid,
  action      text not null,
  target      text not null default '',
  data        jsonb not null default '{}',
  created_at  timestamptz not null default now()
);
create index audit_merchant on audit_log(merchant_id, created_at desc);
