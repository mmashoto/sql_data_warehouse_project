/*
=================================================================================
Quality Checks
=================================================================================
Script Purpose:
      This script performs various quality checks for data consistency, accuracy,
	  and standardization across the 'silver' layer schemas. It includes checks for:
	  - Nulls or duplicates primary keys.
	  - Unwanted spaces in string fields.
	  - Data standardization and consistency.
	  - Invalid dates ranges and orders.
	  - Data consistency between related fields.

Usage Notes:
     - Run this checks after data loading Silver Layer.
     - Investigate and resolve any discrepancies found during the checks.
=================================================================================
*/



-- ------------------------------------CRM Tables--------------------------------
-- ==============================================================================
-- Checking 'silver.crm_cust_info'
-- ==============================================================================
-- Check for NULLS or duplicate keys
-- Expectation : No results 
SELECT 
     cst_id,
     COUNT(*) 
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Checking for unwanted spaces
-- Expectation = No results
SELECT 
     cst_firstname, 
     cst_lastname
FROM silver.crm_cust_info
WHERE 
     (cst_firstname <>  TRIM(cst_firstname)) OR  
     (cst_lastname <> TRIM(cst_lastname));

-- Data standardization and consistency
SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info

/*  
Usage Notes:
Aim to store values that are meaningful & clear, rather than using abbreviated terms.
Hint:
- F = Female
- M = Male
- NULLS = 'n/a' or 'unknown'
*/

-- ==============================================================================
-- Checking 'silver.crm_prd_info'
-- ==============================================================================
-- Check for NULLS or duplicates in Primary keys
-- Expectation : No results 
SELECT 
     prd_id,
	 COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) >1 OR prd_id IS NULL;

-- Checking for unwanted spaces
-- Expectation = No results
SELECT  prd_nm
FROM silver.crm_prd_info
WHERE (prd_nm <>  TRIM(prd_nm)) 

-- Checking for nulls or negative numbers in the field 'prd_cost'
-- Business Rule: cost should never be NULL or negative
-- Expectation = No results 
SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost IS NULL OR prd_cost< 0;

-- Data standardization and consistency
-- field 'prd_line'
/*  
Usage Notes:
Aim to store values that are meaningful & clear, rather than using abbreviated terms
to increase cardinality.
Hint: Find out what the abbreviation stand for from the source expert.
*/
SELECT DISTINCT(prd_line)
FROM silver.crm_prd_info;

-- Checking for invalid dates ranges and orders 
-- Hint: The end date <  start date 
-- Expectation : No results
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt <prd_start_dt;

-- Data standardization and consistency
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info;

-- ==============================================================================
-- Checking 'silver.crm_sales_details'
-- ==============================================================================

-- Checking for unwanted spaces
-- Expectation = No results
SELECT  sls_ord_num
FROM silver.crm_sales_details
WHERE (sls_ord_num <>  TRIM(sls_ord_num)) 

-- Checking for matching keys and ids
-- Fields: 'sls_prd_key', 'sls_cust_key' respectively
-- Expectation : No results
SELECT sls_prd_key
FROM bronze.crm_sales_details
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info);

SELECT sls_cust_id
FROM bronze.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info);

-- Check for Invalid Dates
-- Expectation: No Invalid Dates
SELECT 
    NULLIF(sls_due_dt, 0) AS sls_due_dt 
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0 -- negative numbers or zero can not be cased as a date
    OR LEN(sls_due_dt) != 8 
    OR sls_due_dt > 20500101 --highest limit of an end date of the business
    OR sls_due_dt < 19000101; -- when the business commenced

-- Check for Invalid Date Orders 
-- Hint : Order Date > Shipping/Due Dates
-- Expectation: No Results
SELECT 
    * 
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt 
   OR sls_order_dt > sls_due_dt;

-- Check Data Consistency: Sales = Quantity * Price
/* 
Business rules 
------------------------------------------------------------------------
-->> SUM(Sales) = Quantity * Price
-->> All sales, quantity and price can not be NEGATIVE, ZERO, OR NULL
-------------------------------------------------------------------------
Rule which we used to transform 'bad'data:
	-if sale is negative, zero or null, derive it using quantity and price 
	-if the price is incorrect (null,zeros), then, recalculate it using sales and quantity
	-if price is negative, then convert into positive value 
*/
-- Expectation: No Results
SELECT DISTINCT 
    sls_sales,
    sls_quantity,
    sls_price 
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL 
   OR sls_quantity IS NULL 
   OR sls_price IS NULL
   OR sls_sales <= 0 
   OR sls_quantity <= 0 
   OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;

	 
-- ------------------------------------ERP Tables--------------------------------
-- ==============================================================================
-- Checking 'silver.erp_cust_az12'
-- ==============================================================================
-- Check for NULLS or duplicates in the primary keys
-- Expectation : No results 
 SELECT 
		 CASE 
		      WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4,LEN(cid))
			  ELSE cid
		 END AS cid
 FROM silver.erp_cust_az12
 WHERE CASE 
		  WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4,LEN(cid))
			  ELSE cid
		 END  NOT IN (SELECT DISTINCT cst_key FROM silver.crm_cust_info);

-- Identify Out-of-Range Dates
-- Expectation: Birthdates between 1924-01-01 and Today
SELECT DISTINCT 
    bdate 
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01' 
   OR bdate > GETDATE();

-- Data Standardization & Consistency
SELECT DISTINCT 
    gen 
FROM silver.erp_cust_az12;



-- ==============================================================================
-- Checking 'silver.erp_loc_a101'
-- ==============================================================================
-- Data Standardization & Consistency
SELECT DISTINCT 
    cntry 
FROM silver.erp_loc_a101
ORDER BY cntry;

-- ==============================================================================
-- Checking 'silver.erp_px_cat_g1v2'
-- ==============================================================================
-- Check for Unwanted Spaces
-- Expectation: No Results
SELECT 
    * 
FROM silver.erp_px_cat_g1v2
WHERE cat <> TRIM(cat) 
   OR subcat <> TRIM(subcat) 
   OR maintenance <> TRIM(maintenance);

-- Data Standardization & Consistency
SELECT DISTINCT 
    maintenance 
FROM silver.erp_px_cat_g1v2;


