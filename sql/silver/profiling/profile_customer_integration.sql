/*
===============================================================================
CUSTOMER CROSS-SOURCE INTEGRATION PROFILING
===============================================================================

Sources:
    bronze.crm_cust_info
    bronze.erp_cust_az12
    bronze.erp_loc_a101

Purpose:
    Determine whether customer records from CRM and ERP can be reliably
    connected through a standardized customer key before implementing the
    Silver customer transformation.

Examples:

    CRM:
        AW00011000

    ERP Customer:
        NASAW00011000
        AW00011000

    ERP Location:
        AW-00011000

Candidate canonical customer-key format:

        AW00011000

Candidate normalization rules:

    CRM:
        TRIM(cst_key)

    ERP Customer:
        NASAW00011000 -> AW00011000
        AW00011000    -> AW00011000

    ERP Location:
        AW-00011000   -> AW00011000

===============================================================================
SECTION 1: INSPECT NORMALIZED ERP IDENTIFIERS
===============================================================================

Purpose:
    Confirm that the candidate normalization rules produce the same customer
    key format in ERP Customer and ERP Location.

This query is for inspection only. Reconciliation and validation are performed
in the following sections.
===============================================================================
*/

WITH erp_customers AS (
    SELECT
        cid AS original_cid,

        CASE
            WHEN LEFT(TRIM(cid), 3) = 'NAS'
                THEN SUBSTRING(TRIM(cid), 4)
            ELSE TRIM(cid)
        END AS customer_key,

        bdate,
        gen

    FROM bronze.erp_cust_az12
),

erp_location AS (
    SELECT
        cid AS original_cid,
        REPLACE(TRIM(cid), '-', '') AS customer_key,
        cntry

    FROM bronze.erp_loc_a101
)

SELECT
    ec.original_cid AS customer_original_cid,
    el.original_cid AS location_original_cid,
    ec.customer_key,
    el.cntry
FROM erp_customers AS ec
INNER JOIN erp_location AS el
    ON ec.customer_key = el.customer_key;


/*
===============================================================================
SECTION 2: COUNT MATCHED ERP CUSTOMER <-> ERP LOCATION RECORDS
===============================================================================
*/

WITH erp_customers AS (
    SELECT
        CASE
            WHEN LEFT(TRIM(cid), 3) = 'NAS'
                THEN SUBSTRING(TRIM(cid), 4)
            ELSE TRIM(cid)
        END AS customer_key

    FROM bronze.erp_cust_az12
),

erp_location AS (
    SELECT
        REPLACE(TRIM(cid), '-', '') AS customer_key

    FROM bronze.erp_loc_a101
)

SELECT
    COUNT(*) AS matched_rows
FROM erp_customers AS ec
INNER JOIN erp_location AS el
    ON ec.customer_key = el.customer_key;


/*
===============================================================================
SECTION 3: FIND ERP CUSTOMERS WITHOUT A LOCATION
===============================================================================
*/

WITH erp_customers AS (
    SELECT
        cid AS original_cid,

        CASE
            WHEN LEFT(TRIM(cid), 3) = 'NAS'
                THEN SUBSTRING(TRIM(cid), 4)
            ELSE TRIM(cid)
        END AS customer_key

    FROM bronze.erp_cust_az12
),

erp_location AS (
    SELECT
        cid AS original_cid,
        REPLACE(TRIM(cid), '-', '') AS customer_key

    FROM bronze.erp_loc_a101
)

SELECT
    ec.original_cid,
    ec.customer_key
FROM erp_customers AS ec
LEFT JOIN erp_location AS el
    ON ec.customer_key = el.customer_key
WHERE el.customer_key IS NULL;


/*
Expected result for current data:

    0 rows

Meaning:
    Every ERP customer has a corresponding ERP location.
*/


/*
===============================================================================
SECTION 4: FIND ERP LOCATIONS WITHOUT A CUSTOMER
===============================================================================
*/

WITH erp_customers AS (
    SELECT
        cid AS original_cid,

        CASE
            WHEN LEFT(TRIM(cid), 3) = 'NAS'
                THEN SUBSTRING(TRIM(cid), 4)
            ELSE TRIM(cid)
        END AS customer_key

    FROM bronze.erp_cust_az12
),

erp_location AS (
    SELECT
        cid AS original_cid,
        REPLACE(TRIM(cid), '-', '') AS customer_key

    FROM bronze.erp_loc_a101
)

SELECT
    el.original_cid,
    el.customer_key
FROM erp_location AS el
LEFT JOIN erp_customers AS ec
    ON el.customer_key = ec.customer_key
WHERE ec.customer_key IS NULL;


/*
Expected result for current data:

    0 rows

Meaning:
    Every ERP location belongs to a corresponding ERP customer.
*/


/*
===============================================================================
SECTION 5: ERP CUSTOMER <-> ERP LOCATION FINDINGS
===============================================================================

Actual results:

    ERP Customer rows:             18,484
    ERP Location rows:             18,484
    Matched rows:                  18,484
    Customers without location:         0
    Locations without customer:         0

Findings:

    1. Both ERP datasets contain 18,484 records.

    2. After normalization, all 18,484 ERP Customer records match an
       ERP Location record.

    3. No ERP customers are missing location records.

    4. No ERP location records are missing corresponding customer records.

    5. Normalized customer keys are unique in the current ERP datasets.

Conclusion:

    The normalized customer_key provides a one-to-one relationship between:

        bronze.erp_cust_az12
                <->
        bronze.erp_loc_a101

===============================================================================
*/

/*
===============================================================================
SECTION 6: FINDING DUPLICATE KEYS IN CRM
===============================================================================
*/
WITH crm_customers AS (
    SELECT
        cst_id,
        TRIM(cst_key) AS customer_key,
        cst_firstname,
        cst_lastname,
        cst_marital_status,
        cst_gndr,
        cst_create_date
    FROM bronze.crm_cust_info
)
SELECT
    customer_key,
    COUNT(*) AS occurrence_count
FROM crm_customers
GROUP BY customer_key
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC, customer_key;

/*
========================================
INSPECTING ALL DETAILS OF DUPLICATE CUSTOMERS
========================================
*/

with crm_customers as (
    SELECT cst_id,
        trim(cst_key) as customer_key,
        cst_firstname,
        cst_lastname,
        cst_marital_status,
        cst_gndr,
        cst_create_date
    FROM bronze.crm_cust_info

),
duplicate_key_detection as (
    SELECT count(*), customer_key
    from crm_customers
    group by customer_key 
    having count(*) > 1
)
select c.*
from crm_customers as c
inner join duplicate_key_detection as d 
on c.customer_key = d.customer_key

/*
========================================
RANKING duplicate customers based on Date
========================================
*/

with duplicate_customers as (
	select trim(cst_key) as dublicated_customers
	from bronze.crm_cust_info cci 
	group by trim(cst_key)
	having count(*) > 1
)
select c.* , row_number() over(partition by trim(c.cst_key) order by c.cst_create_date desc) as ranked
from bronze.crm_cust_info c
inner join duplicate_customers as d 
on d.dublicated_customers = trim(c.cst_key)


---- checking validity is different from uniqueness
with ranked_customers as (
select trim(cst_key) as customer_key,
        cst_firstname,
        cst_lastname,
        cst_marital_status,
        cst_gndr,
        cst_create_date,
row_number() over(partition by trim(cst_key) order by cst_create_date desc) as ranked_rows
from bronze.crm_cust_info
),
deduplicated_crm as (
	select * 
	from ranked_customers
	where ranked_rows = 1
)
select count(*) as invalid_keys
from deduplicated_crm 
where customer_key !~ '^AW\d{8}$'

-----complete cte chain--------
WITH ranked_customers AS (
    SELECT
        TRIM(cst_key) AS customer_key,
        cst_firstname,
        cst_lastname,
        cst_marital_status,
        cst_gndr,
        cst_create_date,

        ROW_NUMBER() OVER (
            PARTITION BY TRIM(cst_key)
            ORDER BY cst_create_date DESC
        ) AS row_num

    FROM bronze.crm_cust_info
),

deduplicated_crm AS (
    SELECT *
    FROM ranked_customers
    WHERE row_num = 1
),

valid_crm_customers AS (
    SELECT *
    FROM deduplicated_crm
    WHERE customer_key ~ '^AW[0-9]{8}$'
),

erp_customers AS (
    SELECT
        CASE
            WHEN LEFT(TRIM(cid), 3) = 'NAS'
                THEN SUBSTRING(TRIM(cid), 4)
            ELSE TRIM(cid)
        END AS customer_key,
        bdate,
        gen

    FROM bronze.erp_cust_az12
)

SELECT
    COUNT(*) AS matched_customers
FROM valid_crm_customers AS crm
INNER JOIN erp_customers AS erp
    ON crm.customer_key = erp.customer_key;


-----Which valid CRM customers do not exist in ERP?-----
WITH ranked_customers AS (
    SELECT
        TRIM(cst_key) AS customer_key,
        cst_firstname,
        cst_lastname,
        cst_marital_status,
        cst_gndr,
        cst_create_date,

        ROW_NUMBER() OVER (
            PARTITION BY TRIM(cst_key)
            ORDER BY cst_create_date DESC
        ) AS row_num

    FROM bronze.crm_cust_info
),

deduplicated_crm AS (
    SELECT *
    FROM ranked_customers
    WHERE row_num = 1
),

valid_crm_customers AS (
    SELECT *
    FROM deduplicated_crm
    WHERE customer_key ~ '^AW[0-9]{8}$'
),

erp_customers AS (
    SELECT
        CASE
            WHEN LEFT(TRIM(cid), 3) = 'NAS'
                THEN SUBSTRING(TRIM(cid), 4)
            ELSE TRIM(cid)
        END AS customer_key,
        bdate,
        gen

    FROM bronze.erp_cust_az12
)
SELECT
    crm.customer_key
FROM valid_crm_customers AS crm
LEFT JOIN erp_customers AS erp
    ON crm.customer_key = erp.customer_key
WHERE erp.customer_key IS NULL;



/*
===============================================================================
CRM <-> ERP CUSTOMER RECONCILIATION FINDINGS
===============================================================================

CRM:
    Raw rows:                         18,494
    Distinct customer keys:           18,488
    Extra rows from duplicate keys:        6
    Invalid/noncanonical keys:             4
    Valid deduplicated customer keys: 18,484

ERP Customer:
    Normalized customer keys:         18,484

Cross-source reconciliation:
    Matched customers:                18,484
    CRM customers without ERP:             0
    ERP customers without CRM:             0

ERP Customer <-> ERP Location:
    Matched customers:                18,484
    ERP customers without location:        0
    Locations without ERP customer:        0

Findings:
    - CRM contains multiple versions of several customer records.
    - Ranking records by customer_key and cst_create_date DESC produces one
      candidate current record per CRM customer key.
    - CRM contains four noncanonical customer keys.
    - After CRM deduplication and exclusion of those four noncanonical keys,
      18,484 valid CRM customer keys remain.
    - All 18,484 valid CRM customer keys match normalized ERP customer keys.
    - All normalized ERP customer keys have corresponding ERP location records.
    */