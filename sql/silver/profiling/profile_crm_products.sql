-- profiling id----
select count(*) as total_rows,
count(distinct trim(prd_id)) as distinct_id,
count(*) filter ( where trim(prd_id) = '') as blank_ids,
count(*) filter (where trim(prd_id) is null) as null_ids,
count(*) filter (where trim(prd_id) !~ '^[0-9]+$') as none_numeric
from bronze.crm_prd_info cpi 

-- profiling key----

select count(*) as total_rows,
count(*) filter (where trim(prd_key) is null) as null_count,
count(*) filter (where trim(prd_key) ='') as blank_count,
count(distinct trim(prd_key)) as distinct_key
from bronze.crm_prd_info 

-- selecting duplicated rows with prd_key---

select * 
from (
	select count(*) over(partition by trim(prd_key)) as key_count,cpi.*
	from bronze.crm_prd_info cpi
)
where key_count >1
order by key_count


-- profiling prd_start_dt ----------------

select count(*) as total_count, 
count(*) filter (where trim(prd_start_dt) is null) as null_count,
count(*) filter (where trim(prd_start_dt) = '') as blank_count,
count(*) filter (where trim(prd_start_dt) !~ '^\d{4}-\d{2}-\d{2}$') as invalid_format,
count(*) filter(where trim(prd_start_dt)::DATE > current_date) as invalid_start
from bronze.crm_prd_info 

-- profiling prd_end_dt------------

select count(*) as total_count, 
count(*) filter (where trim(prd_end_dt) is null) as null_count,
count(*) filter (where trim(prd_end_dt) = '') as blank_count,
count(*) filter (where trim(prd_end_dt) !~ '^\d{4}-\d{2}-\d{2}$') as invalid_format,
count(*) filter(where trim(prd_end_dt)::DATE > current_date) as invalid_start,
count(*) filter (where trim(prd_start_dt)::DATE >  trim(prd_end_dt)::DATE) as invalid_range
from bronze.crm_prd_info 

----- checking the average dates between each start date----

with start_date_check as (
	select prd_id,trim(prd_key) as product_id,
	trim(prd_start_dt)::DATE as start_date,
	lead(trim(prd_start_dt)::DATE)
	over(partition by trim(prd_key) order by trim(prd_start_dt)::DATE) as next_start
	from bronze.crm_prd_info
)
select * , next_start - start_date as days_between
from start_date_check


select *
from bronze.crm_prd_info 

---alidate that there aren't two versions of the same product starting on the same date.---
SELECT
    TRIM(prd_key) AS product_key,
    TRIM(prd_start_dt)::DATE AS start_date,
    COUNT(*) AS version_count
FROM bronze.crm_prd_info
GROUP BY
    TRIM(prd_key),
    TRIM(prd_start_dt)::DATE
HAVING COUNT(*) > 1;

-- profiling prd_nm ----
select count(*) as total_rows,
count(distinct trim(prd_nm)) as distinct_name,
count(*) filter (where trim(prd_nm) = '') as blank_names,
count(*) filter (where trim(prd_nm) is null) as null_names,
count(*) filter (where trim(prd_nm) <> prd_nm) as spaces_count
from bronze.crm_prd_info cpi 

select prd_id,prd_key, prd_nm,
count(*) over(partition by trim(prd_nm)) as duplicated_names
from bronze.crm_prd_info 

-- profiling prd_cost -------
select count(*) as total_rows,
count(*) filter (where trim(prd_cost) is null) as null_count,
count(*) filter (where trim(prd_cost) = '') as blank_count,
count(*) filter(where trim(prd_cost) !~ '^[0-9]+(\.[0-9]+)?$') as invalid_integer,
count(*) filter (where trim(prd_cost) <> prd_cost) as trail_head_space, 
max(trim(prd_cost)::numeric) as max_cost,
min(trim(prd_cost)::numeric) as min_cost
from bronze.crm_prd_info 

-- profiling prd_ine------
select count(*) as total_rows,
count(*) filter (where trim(prd_line) is null) as null_count,
count(*) filter (where trim(prd_line) = '') as blank_count,
count(*) filter (where trim(prd_line) <> prd_line) as trail_head_space
from bronze.crm_prd_info 

select trim(prd_line), count(*) as each_line
from bronze.crm_prd_info 
group by trim(prd_line)


profiling erp_px_cat_g1v2

select * 
from bronze.erp_px_cat_g1v2 epcgv 

-- profiling id----
select count(*) as total_rows,
count(distinct trim(id)) as distinct_id,
count(*) filter (where trim(id) = '') as blank_ids,
count(*) filter (where trim(id) is null) as null_ids,
count(*) filter (where trim(id) !~ '^[A-Z]{2}_[A-Z]{2}$') as format_check
from bronze.erp_px_cat_g1v2 epcgv 

-- profiling cat ----
select count(*) as total_rows,
count(distinct trim(cat)) as distinct_name,
count(*) filter (where trim(cat) = '') as blank_names,
count(*) filter (where trim(cat) is null) as null_names,
count(*) filter (where trim(cat) <> cat) as spaces_count
from bronze.erp_px_cat_g1v2 epcgv 

-- profiling subcat ----
select count(*) as total_rows,
count(distinct trim(subcat)) as distinct_name,
count(*) filter (where trim(subcat) = '') as blank_names,
count(*) filter (where trim(subcat) is null) as null_names,
count(*) filter (where trim(subcat) <> subcat) as spaces_count
from bronze.erp_px_cat_g1v2 epcgv 

--profiling maintencane--
SELECT
    TRIM(maintenance) AS maintenance,
    COUNT(*) AS row_count
FROM bronze.erp_px_cat_g1v2
GROUP BY TRIM(maintenance)
ORDER BY row_count DESC;

SELECT
    COUNT(*) AS total_rows,

    COUNT(*) FILTER (
        WHERE maintenance IS NULL
    ) AS null_count,

    COUNT(*) FILTER (
        WHERE maintenance IS NOT NULL
          AND TRIM(maintenance) = ''
    ) AS blank_count,

    COUNT(*) FILTER (
        WHERE maintenance <> TRIM(maintenance)
    ) AS spaces_count

FROM bronze.erp_px_cat_g1v2;




