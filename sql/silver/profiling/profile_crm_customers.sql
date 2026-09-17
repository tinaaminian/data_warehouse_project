-- ============================================================================
-- PROFILING FINDINGS
-- ============================================================================

/*
Customer Key Findings
---------------------
- Total rows: 18,494
- 18,490 cst_key values follow the dominant 10-character pattern beginning AW0.
- 4 records have different key structures:
    SF566
    PO25
    13451235
    A01Ass
- These four records appear to have missing customer attributes.
- Their meaning must be investigated before defining the Silver
  customer-key validation rule.
*/

-- Checking whether there is null or duplicates using COUNT()
select count(*) as total_rows,
count(cst_id) as not_null_ids,
count(*) - count(cst_id) as null_ids,
count(distinct(cst_id)) as distinct_ids
from bronze.crm_cust_info ;

-- Checking specificly for NULLs
select
    COUNT(*) FILTER (WHERE cst_id IS NULL) AS null_cst_id,
    COUNT(*) FILTER (WHERE cst_key IS NULL) AS null_cst_key,
    COUNT(*) FILTER (WHERE cst_firstname IS NULL) AS null_firstname,
    COUNT(*) FILTER (WHERE cst_lastname IS NULL) AS null_lastname,
    COUNT(*) FILTER (WHERE cst_marital_status IS NULL) AS null_marital_status,
    COUNT(*) FILTER (WHERE cst_gndr IS NULL) AS null_gender,
    COUNT(*) FILTER (WHERE cst_create_date IS NULL) AS null_create_date
from bronze.crm_cust_info;

-- Checking specificly for duplicate IDs
select cst_id, count(cst_id) as occurance_count
from bronze.crm_cust_info cci 
where cci.cst_id is NOT NULL
group by cst_id
having count(cst_id) > 1  
order by occurance_count DESC;

-- Checking for white space 
select cst_firstname 
from bronze.crm_cust_info cci 
where cci.cst_firstname != trim(cci.cst_firstname);

-- Checking for white space 
select count(*)
from bronze.crm_cust_info cci 
where cci.cst_lastname  != trim(cci.cst_lastname)

-- Counting how many of firstnames contain whitespace
select count(*)
from bronze.crm_cust_info cci
where cci.cst_firstname != trim(cci.cst_firstname);

-- Marital Status is categorical, we want to know how many each has
select count(*), cst_marital_status
from bronze.crm_cust_info 
group by cst_marital_status 

-- Chekcing cst_key
select cst_key
from bronze.crm_cust_info cci 
where cst_key is null 

select count(distinct cst_key), count(cst_key)
from bronze.crm_cust_info 

select count(*), cst_key
from bronze.crm_cust_info
where cst_key is not null
group by cst_key
having count(*)>1

select count(*)
from bronze.crm_cust_info cci 
where cst_key != trim(cci.cst_key)

-- ==========================Date=======================
-- Profiling date 1- checking for NULL
select count(*)
from bronze.crm_cust_info cci 
where cci.cst_create_date is null

-- Profiling date 2- checking for empty or blank '' or ' '
select count(*) as blank_create_dates
from bronze.crm_cust_info 
where trim(cst_create_date) =''

-- Checking for format using Regex
select cst_create_date
from bronze.crm_cust_info
where cst_create_date is not null AND
trim(cst_create_date) != '' AND
trim(cst_create_date) !~ '^\d{4}-\d{2}-\d{2}$';

-- Checking whether it can convert into Date successfully or not
select cst_create_date, cst_create_date::DATE as converted_date
from bronze.crm_cust_info 
where cst_create_date is not null and 
trim(cst_create_date) != ''

-- length------------------------------------------------
select count(*),length(trim(cst_key)) as character_count
from bronze.crm_cust_info
where cst_key is not null 
group by length(trim(cst_key))

select * 
from bronze.crm_cust_info
where cst_key is not null and length(trim(cst_key)) != 10

select count(*), length(trim(cid))
from bronze.erp_cust_az12
where cid is not null 
group by length(trim(cid))

select count(*) , length(trim(cid))
from bronze.erp_loc_a101 ela 
where cid is not null  
group by length(trim(cid))

----prefix-------------------------------------------
select count(*), left(trim(cid),3) as prefix_chars
from bronze.erp_loc_a101 ela 
where cid is not null 
group by left(trim(cid),3)

select count(*), left(trim(cci.cst_key),3) as prefix_chars
from bronze.crm_cust_info cci 
where cci.cst_key is not null 
group by left(trim(cci.cst_key),3)

select count(*), left(trim(cid),3) as prefix_chars
from bronze.erp_cust_az12  
where cid is not null 
group by left(trim(cid),3)
