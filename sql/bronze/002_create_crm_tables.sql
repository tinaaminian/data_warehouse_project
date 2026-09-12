create table if not exists bronze.crm_cust_info(
    cst_id text,
    cst_key text,
    cst_firstname text,
    cst_lastname text,
    cst_marital_status text,
    cst_gndr text,
    cst_create_date text,

    source_file text not null,
    batch_id text not null,
    ingested_at timestamptz not null default now()
);

create table if not exists bronze.crm_prd_info(
    prd_id                   TEXT,
    prd_key                  TEXT,
    prd_nm                   TEXT,
    prd_cost                 TEXT,
    prd_line                 TEXT,
    prd_start_dt             TEXT,
    prd_end_dt               TEXT, 

    source_file text not null,
    batch_id text not null,
    ingested_at timestamptz not null default now()
);

create table if not exists bronze.crm_sales_details(
      sls_ord_num              TEXT,
    sls_prd_key              TEXT,
    sls_cust_id              TEXT,
    sls_order_dt             TEXT,
    sls_ship_dt              TEXT,
    sls_due_dt               TEXT,
    sls_sales                TEXT,
    sls_quantity             TEXT,
    sls_price                TEXT,

    source_file              TEXT NOT NULL,
    batch_id                 TEXT NOT NULL,
    ingested_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
)