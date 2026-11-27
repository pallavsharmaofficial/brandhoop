-- iPhone management through an MDM server (NanoMDM)
alter table devices add column mdm_udid text;
alter table devices add column mdm_enrolled_at timestamptz;
create unique index devices_mdm_udid on devices(mdm_udid) where mdm_udid is not null;
create index devices_serial on devices(upper(serial)) where serial <> '';

create table mdm_commands (
  uuid         uuid primary key,
  device_id    uuid not null references devices(id),
  request_type text not null,
  status       text not null default 'queued', -- queued | Acknowledged | Error | NotNow | failed
  error        text,
  created_at   timestamptz not null default now(),
  acked_at     timestamptz
);
create index mdm_commands_device on mdm_commands(device_id, created_at desc);
