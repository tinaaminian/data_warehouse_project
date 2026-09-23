with crm_product as (
    select 
        nullif(trim(prd_id), '')::INTEGER  as product_id,
        nullif(trim(prd_key),'') as product_key,
        nullif(trim(prd_nm), '') as product_name,
        replace(left(trim(prd_key),5),'-','_') as source_category_id,
        nullif(trim(prd_cost),'')::NUMERIC as cost, 
        nullif(trim(prd_line),'') as product_line, 
        nullif(trim(prd_start_dt),'')::DATE as start_date,
        batch_id as crm_batch_id
    from bronze.crm_prd_info 
),
crm_mapped as (
    select * , 
        case 
            when source_category_id = 'CO_PE' then 'CO_PD'
            else source_category_id
        end as category_id
    from crm_product
),
crm_versioned as (
    select * ,
     lead(start_date)
     over(partition by product_key order by start_date) as next_start_date,
     lead(start_date)
     over(partition by product_key order by start_date) - 1 as end_date
    from crm_mapped
),
erp_product as(
    select
        nullif(trim(id),'') as id,
        nullif(trim(cat),'') as category, 
        nullif(trim(subcat),'') as subcategory, 
        case 
            when  upper(trim(maintenance)) = 'YES' then TRUE
            when upper(trim(maintenance)) = 'NO' then FALSE 
            else NULL 
        end as maintenance, 
         batch_id as erp_category_batch_id
    from bronze.erp_px_cat_g1v2
) 
INSERT INTO silver.products(
   product_id,
   product_key,
   product_name,
   category_id,
   category,
   subcategory,
   maintenance,
   cost,
   product_line,
   start_date,
   end_date,

   crm_batch_id,
   erp_category_batch_id
)
select
 cv.product_id,
 cv.product_key,
 cv.product_name, 
 cv.category_id, ep.category, 
 ep.subcategory, ep.maintenance, cv.cost,
cv.product_line,
 cv.start_date,
 cv.end_date,
 cv.crm_batch_id,
 ep.erp_category_batch_id

from crm_versioned as cv
inner join erp_product as ep
on cv.category_id = ep.id

