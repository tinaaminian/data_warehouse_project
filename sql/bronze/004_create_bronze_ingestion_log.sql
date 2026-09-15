create table if not exists bronze.ingestion_log(
    batch_id UUID PRIMARY KEY,
    source_system TEXT NOT NULL,
    source_file TEXT NOT NULL,
    file_hash TEXT NOT NULL CHECK(length(file_hash) = 64),
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    status TEXT NOT NULL CHECK(status IN ('STARTED', 'SUCCESS' , 'FAILED')),
    rows_loaded BIGINT CHECK( rows_loaded >= 0 ),
    error_message TEXT
)