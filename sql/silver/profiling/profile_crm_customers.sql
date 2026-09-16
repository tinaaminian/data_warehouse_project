-- Checking whether there is null or duplicates using COUNT()
select count(*) as total_rows,
count(cst_id) as not_null_ids,
count(*) - count(cst_id) as null_ids,
count(distinct(cst_id)) as distinct_ids
from bronze.crm_cust_info ;

-- Checking specificly for NULLs
select cst_id,cci.cst_firstname,cci.cst_key 
from bronze.crm_cust_info cci 
where cst_id is null ;

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


-- Counting how many of firstnames contain whitespace
select count(*)
from bronze.crm_cust_info cci
where cci.cst_firstname != trim(cci.cst_firstname);