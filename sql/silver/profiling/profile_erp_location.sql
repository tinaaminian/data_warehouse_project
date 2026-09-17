-- Q1. How many rows are in erp_loc_a101?

-- Q2. How many CID values are NULL?

-- Q3. How many distinct CID values are there?

-- Q4. Are there duplicate CIDs?
--     If yes, which ones and how many times?

-- Q5. Are there leading/trailing spaces in CID?

-- Q7. How many CNTRY values are NULL?

-- Q8. How many CNTRY values are blank/whitespace-only?

-- Q9. Do any country values have leading/trailing whitespace?

-- Q10. What distinct country values exist and how many rows belong to each?

-- How many rows
select count(*)
from bronze.erp_loc_a101

-- NULL values
select count(*)
from bronze.erp_loc_a101
where cid is NULL 

-- Checking for duplicate values
select count(distinct cid)
from bronze.erp_loc_a101

select cid, count(*)
from bronze.erp_loc_a101 
where cid is not null 
group by cid 
having count(*) > 1

-- checking for format:
select cid 
from bronze.erp_loc_a101 
where cid !~ '^[A-Za-z]{2}-\d{8}$'

-- checking for leading/trailing spaces
select count(*)
from bronze.erp_loc_a101
where cid != trim(cid)

-- profiling cntry
select count(cntry)
from bronze.erp_loc_a101

select count(*)
from bronze.erp_loc_a101
where cntry is null 

select count(cid), cid
from bronze.erp_loc_a101
where cid is not null 
group by cid
having count(cid) > 1

select *
from bronze.erp_loc_a101
where cntry != trim(cntry)

select *
from bronze.erp_loc_a101
where trim(cntry) = '' 

select trim(cntry), count(*)
from bronze.erp_loc_a101
where cntry is not null 
group by trim(cntry) 
