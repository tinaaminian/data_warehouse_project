alter table bronze.crm_cust_info
alter column batch_id type UUID using batch_id::UUID;

alter table bronze.crm_prd_info
alter column batch_id type UUID using batch_id::UUID;

alter table bronze.crm_sales_details
alter column batch_id type UUID using batch_id::UUID;

alter table bronze.erp_cust_az12
alter column batch_id type UUID using batch_id::UUID;

alter table bronze.erp_loc_a101
alter column batch_id type UUID using batch_id::UUID;

alter table bronze.erp_px_cat_g1v2
alter column batch_id type UUID using batch_id::UUID;