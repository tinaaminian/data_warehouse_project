/*
===============================================================================
ERP CUSTOMER DATA PROFILING
Source: bronze.erp_cust_az12
===============================================================================

Purpose:
Understand the quality and structure of the ERP customer data before designing
and transforming it into the Silver layer.

-------------------------------------------------------------------------------
1. ROW COUNT / COMPLETENESS
-------------------------------------------------------------------------------
Q1. How many rows are in the source table?

-------------------------------------------------------------------------------
2. CUSTOMER ID (CID) PROFILING
-------------------------------------------------------------------------------
Q2. How many CID values are NULL?

Q3. How many distinct CID values exist?

Q4. Are there duplicate CID values?
    If yes, which CIDs are duplicated and how many times does each occur?

Q5. Do any CID values contain leading or trailing whitespace?

-------------------------------------------------------------------------------
3. GENDER (GEN) PROFILING
-------------------------------------------------------------------------------
Q6. What distinct gender values exist in the source?

Q7. How many rows belong to each gender value after removing leading/trailing
    whitespace?

Q8. Are there NULL gender values?

Q9. Are there blank or whitespace-only gender values?

Q10. Are multiple representations being used for the same gender
     (for example: 'Male' and 'M', or 'Female' and 'F')?

-------------------------------------------------------------------------------
4. BIRTH DATE (BDATE) PROFILING
-------------------------------------------------------------------------------
Q11. How many birth dates are NULL?

Q12. Are there blank or whitespace-only birth dates?

Q13. Do all populated birth dates follow the expected YYYY-MM-DD format?

Q14. Can the populated birth-date values be safely converted from TEXT
     to PostgreSQL DATE?

Q15. What are the earliest and latest birth dates in the dataset?

Q16. Are there birth dates later than the current/reference date?

Q17. Are there unusually old birth dates that should be investigated
     against business requirements?

-------------------------------------------------------------------------------
5. PROFILING FINDINGS / SILVER CONSIDERATIONS
-------------------------------------------------------------------------------
The profiling results will be used to determine:

- whether CID can be treated as a reliable identifier;
- how gender values should be standardized;
- how NULL and blank values should be handled;
- how BDATE should be converted from TEXT to DATE;
- how invalid future birth dates should be handled;
- which rules should be implemented and tested in the Silver layer.

IMPORTANT:
Profiling identifies data-quality problems. It does not modify Bronze data.
Transformation and standardization rules will be implemented in Silver.
===============================================================================
*/

select * 
from bronze.erp_cust_az12 

select count(*)
from bronze.erp_cust_az12

select count(*)
from bronze.erp_cust_az12
where cid is null 

select count(distinct cid) 
from bronze.erp_cust_az12 eca 

select cid, count(*)
from bronze.erp_cust_az12 
where cid is not null 
group by cid 
having count(*) > 1

select count(*)
from bronze.erp_cust_az12 eca 
where cid != trim(cid)

select distinct gen
from bronze.erp_cust_az12 eca 

select trim(gen), count(*) 
from bronze.erp_cust_az12 eca 
group by trim(gen) 

select bdate 
from bronze.erp_cust_az12 eca 
where bdate is null or trim(bdate) = ''

SELECT bdate
FROM bronze.erp_cust_az12 AS eca
WHERE bdate IS NOT NULL
  AND TRIM(bdate) <> ''
  AND TRIM(bdate) !~ '^\d{4}-\d{2}-\d{2}$';

select bdate , bdate::DATE as converted_date
from bronze.erp_cust_az12 eca 
WHERE bdate IS NOT NULL
  AND TRIM(bdate) <> '';

select min(bdate::Date) as min_date,
max(bdate::Date) as max_date
from bronze.erp_cust_az12 eca 
WHERE bdate IS NOT NULL
  AND TRIM(bdate) <> '';

select *
from bronze.erp_cust_az12 eca 
where bdate::date  > current_date