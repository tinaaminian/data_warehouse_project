create table if not exists silver.customers(
    customer_id integer not null unique,
    customer_key text primary key check(customer_key ~ '^AW[0-9]{8}$') ,
    first_name text not null,
    last_name text not null,
    marital_status text not null check(marital_status in ('Single', 'Married')),
    gender text check(gender in ('M','F')),
    birth_date Date,
    country text, 
    create_date Date not null,
    crm_batch_id UUID not null ,
    erp_customer_batch_id UUID not null ,
    erp_location_batch_id UUID not null,
    silver_loaded_at TIMESTAMPTZ not null default now()
)