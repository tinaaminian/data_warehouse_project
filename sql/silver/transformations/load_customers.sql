with crm_ranked as (
    select 
        nullif(trim(cst_id), ''):: integer as customer_id,
        trim(cst_key) as customer_key,
        nullif(trim(cst_firstname), '') as  first_name,
        nullif(trim(cst_lastname),'') as last_name,

        case 
            when trim(cst_marital_status) = 'M' then 'Married'
            when trim(cst_marital_status) = 'S' then 'Single'
            else null 
        end as marital_status,

        case
            when trim(cst_gndr) = 'M' then 'M'
            when trim(cst_gndr) = 'F' then 'F'
            else null 
        end as crm_gender,

        nullif(trim(cst_create_date), '')::date as create_date,

        batch_id as crm_batch_id,

        ROW_NUMBER() OVER (
            PARTITION BY TRIM(cst_key)
            ORDER BY NULLIF(TRIM(cst_create_date), '')::DATE DESC
        ) AS row_num

    FROM bronze.crm_cust_info
),

deduplated_crm_customers as (
    select customer_id,
        customer_key,
        first_name,
        last_name,
        marital_status,
        crm_gender,
        create_date,
        crm_batch_id

    from crm_ranked
    where row_num = 1
),

valid_crm_customers as (
    select 
        customer_id,
        customer_key,
        first_name,
        last_name,
        marital_status,
        crm_gender,
        create_date,
        crm_batch_id
    from deduplated_crm_customers
    where customer_key ~ '^AW[0-9]{8}$'
),

erp_customers as(
    select 
        case
            when left(trim(cid),3) = 'NAS' then substring(trim(cid),4)
            else trim(cid)
        end as customer_key,

        case 
            when nullif(trim(bdate),'')::DATE <= current_date then nullif(trim(bdate),'')::Date
            else null
        end as birth_date ,

        case 
            WHEN TRIM(gen) IN ('Male', 'M') THEN 'M'
            WHEN TRIM(gen) IN ('Female', 'F') THEN 'F'
            else null
        end as erp_gender,

        batch_id AS erp_customer_batch_id

    from bronze.erp_cust_az12
),

erp_locations AS (
    SELECT
        REPLACE(TRIM(cid), '-', '') AS customer_key,

        CASE
            WHEN NULLIF(TRIM(cntry), '') IN ('US', 'USA', 'United States')
                THEN 'United States'

            WHEN NULLIF(TRIM(cntry), '') IN ('DE', 'Germany')
                THEN 'Germany'

            ELSE NULLIF(TRIM(cntry), '')
        END AS country,

        batch_id AS erp_location_batch_id

    FROM bronze.erp_loc_a101
),

final_customers AS (
    SELECT
        c.customer_id,
        c.customer_key,
        c.first_name,
        c.last_name,
        c.marital_status,

        COALESCE(c.crm_gender, ec.erp_gender) AS gender,

        ec.birth_date,
        el.country,
        c.create_date,

        c.crm_batch_id,
        ec.erp_customer_batch_id,
        el.erp_location_batch_id

    FROM valid_crm_customers AS c

    INNER JOIN erp_customers AS ec
        ON c.customer_key = ec.customer_key

    INNER JOIN erp_locations AS el
        ON c.customer_key = el.customer_key
)
insert into silver.customers (
    customer_id,
    customer_key,
    first_name,
    last_name,
    marital_status,
    gender,
    birth_date,
    country,
    create_date,
    crm_batch_id,
    erp_customer_batch_id,
    erp_location_batch_id
)
select 
    customer_id,
    customer_key,
    first_name,
    last_name,
    marital_status,
    gender,
    birth_date,
    country,
    create_date,
    crm_batch_id,
    erp_customer_batch_id,
    erp_location_batch_id

from final_customers
