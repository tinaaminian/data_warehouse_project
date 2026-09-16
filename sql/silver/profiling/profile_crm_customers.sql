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