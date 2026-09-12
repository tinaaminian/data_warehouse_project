create table if not exists bronze.erp_cust_az12(
    cid text,
    bdate text,
    gen text,

    source_file text not null,
    batch_id text not null,
    ingested_at timestamptz not null default now()
);

CREATE TABLE IF NOT EXISTS bronze.erp_loc_a101 (
    cid                      TEXT,
    cntry                    TEXT,

    source_file              TEXT NOT NULL,
    batch_id                 TEXT NOT NULL,
    ingested_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


CREATE TABLE IF NOT EXISTS bronze.erp_px_cat_g1v2 (
    id                       TEXT,
    cat                      TEXT,
    subcat                   TEXT,
    maintenance              TEXT,

    source_file              TEXT NOT NULL,
    batch_id                 TEXT NOT NULL,
    ingested_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);