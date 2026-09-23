create table if not exists silver.products(
    product_id INTEGER PRIMARY KEY,
    product_key TEXT NOT NULL ,
    product_name TEXT NOT NULL,
    category_id TEXT NOT NULL CHECK(category_id ~ '^[A-Z]{2}_[A-Z]{2}$'),
    category TEXT,
    subcategory TEXT,
    maintenance BOOLEAN,
    cost NUMERIC, 
    product_line TEXT,
    start_date DATE NOT NULL, 
    end_date DATE CHECK (end_date IS NULL OR end_date >= start_date),

    crm_batch_id UUID NOT NULL, 
    erp_category_batch_id UUID NOT NULL, 
    silver_loaded_at TIMESTAMPTZ NOT NULL default now()
)