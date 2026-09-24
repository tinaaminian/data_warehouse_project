WITH crm_ranked AS (
    SELECT
        TRIM(cst_key) AS customer_key,

        ROW_NUMBER() OVER (
            PARTITION BY TRIM(cst_key)
            ORDER BY NULLIF(TRIM(cst_create_date), '')::DATE DESC
        ) AS row_num

    FROM bronze.crm_cust_info
),

valid_crm_customers AS (
    SELECT
        customer_key
    FROM crm_ranked
    WHERE row_num = 1
      AND customer_key ~ '^AW[0-9]{8}$'
),

erp_customers AS (
    SELECT
        CASE
            WHEN LEFT(TRIM(cid), 3) = 'NAS'
                THEN SUBSTRING(TRIM(cid), 4)
            ELSE TRIM(cid)
        END AS customer_key

    FROM bronze.erp_cust_az12
),

erp_locations AS (
    SELECT
        REPLACE(TRIM(cid), '-', '') AS customer_key

    FROM bronze.erp_loc_a101
),

integrated_customers AS (
    SELECT
        c.customer_key
    FROM valid_crm_customers AS c

    INNER JOIN erp_customers AS ec
        ON c.customer_key = ec.customer_key

    INNER JOIN erp_locations AS el
        ON c.customer_key = el.customer_key
),
missing_customers_from_silver as (
    select *
    FROM valid_crm_customers as vc
    left join silver.customers c 
    on vc.customer_key = c.customer_key 
    where c.customer_key is null
)

SELECT
    (SELECT COUNT(*) FROM valid_crm_customers) AS valid_crm_count,
    (SELECT COUNT(*) FROM integrated_customers) AS integrated_count,
    (SELECT COUNT(*) FROM silver.customers) AS silver_count,
    (SELECT COUNT(*) FROM missing_customers_from_silver) AS missing_from_silver_count