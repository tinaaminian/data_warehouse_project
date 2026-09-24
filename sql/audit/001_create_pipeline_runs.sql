create schema if not exists audit ;


create table if not exists audit.pipeline_runs(
    run_id UUID primary key,
    pipeline_name text not null, 

    started_at TIMESTAMPTZ not null default now(),
    completed_at TIMESTAMPTZ,

    status text not null check(status in ('STARTED', 'SUCCESS', 'FAILED')),
    error_message text
);