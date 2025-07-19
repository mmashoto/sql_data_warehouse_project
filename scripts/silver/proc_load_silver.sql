/*
==================================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
==================================================================================
Script Purpose:
     This stored procedure loads data into the 'bronze' schema from the external
	 CSV files. It performs the following actions:
	 - Truncates the bronze table before loading it.
	 - Uses the 'BULK INSERT' command to load data from the CSV files and 
	 into the bronze tables.

Parameters:
     None.
     This stored procedure does not accept any parameters or return any values.

Usage Example:
     EXEC bronze.load_bronze;   
==================================================================================
*/




CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '=====================================================================';
		PRINT 'Loading the Silver Layer';
		PRINT '=====================================================================';
		PRINT '---------------------------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '---------------------------------------------------------------------';
		
		-- Loading silver.crm_cust_info
		SET @start_time = GETDATE();
		PRINT '>> TRUNCATE Table: silver.crm_cust_info'
		TRUNCATE TABLE silver.crm_cust_info
		PRINT '>> Inserting Data Into: silver.crm_cust_info'

		INSERT INTO silver.crm_cust_info(
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname, 
			cst_marital_status,
			cst_gndr,
			cst_create_date
		)

		SELECT 
			cst_id,
			cst_key,
			TRIM(cst_firstname)  AS cst_firstname,
			TRIM(cst_lastname)   AS cst_lastname,
			CASE TRIM(UPPER(cst_marital_status)) 
				 WHEN 'M' THEN 'Married'
				 WHEN 'S' THEN 'Single' 
				 ELSE 'n/a'
			END cst_marital_status, --Normalise marital status values to readable format
			CASE TRIM(UPPER(cst_gndr))
				 WHEN 'F' THEN 'Female'
				 WHEN 'M' THEN 'Male'
				 ELSE 'n/a'
			END cst_gndr, -- Normalise gender to readable format
			cst_create_date
		FROM ( 
				SELECT *,
				ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
				FROM bronze.crm_cust_info
				WHERE cst_id IS NOT NULL
		) AS t
		WHERE flag_last = 1 ; -- select the most recent records per customer 
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST (DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '.................................'

		-- Loading silver.crm_sales_details
		SET @start_time = GETDATE();
		PRINT '>> TRUNCATE Table: silver.crm_sales_details';
		TRUNCATE TABLE silver.crm_sales_details;
		PRINT '>> Inserting Data Into: silver.crm_sales_details';

		INSERT INTO silver.crm_sales_details(
			  sls_ord_num,
			  sls_prd_key,
			  sls_cust_id,
			  sls_order_dt,
			  sls_ship_dt,
			  sls_due_dt,
			  sls_sales,
			  sls_quantity,
			  sls_price
		)
      
		SELECT
			  sls_ord_num,
			  sls_prd_key,
			  sls_cust_id,
			  CASE 
				   WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
				   ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
			  END sls_order_dt,
			  CASE 
				   WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
				   ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
			  END sls_order_dt,
			  CASE 
				   WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
				   ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
			  END sls_order_dt,
			  CASE 
					WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales <> sls_quantity * ABS(sls_price)
						THEN  sls_quantity * ABS(sls_price)
					ELSE sls_sales
			  END sls_sales, -- Recalculate the sales if the original values are missing or incorrect
			  sls_quantity,
			  CASE 
					WHEN sls_price IS NULL OR sls_price <= 0 
						THEN  sls_sales/ NULLIF(sls_quantity, 0)
					ELSE sls_price
			  END sls_price -- Derive price if the original values are invalid 

		FROM bronze.crm_sales_details;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST (DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '.................................'

		-- Loading silver.crm_prd_info
		SET @start_time = GETDATE();
		PRINT '>> TRUNCATE Table: silver.crm_prd_info';
		TRUNCATE TABLE silver.crm_prd_info;
		PRINT '>> Inserting Data Into: silver.crm_prd_info';

		INSERT INTO silver.crm_prd_info(
				prd_id,
				cat_id,
				prd_key,
				prd_nm,
				prd_cost,
				prd_line,
				prd_start_dt,
				prd_end_dt
		)
		SELECT
				prd_id,
				REPLACE(SUBSTRING(prd_key,1,5), '-', '_') AS cat_id, --extract category id
				SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key, -- extract product id
				prd_nm,
				COALESCE(prd_cost, 0) AS prd_cost,
				CASE TRIM(UPPER(prd_line)) -- map product line code to descriptivr values
					 WHEN 'M' THEN 'Mountain'
					 WHEN 'R' THEN 'Road' 
					 WHEN 'S' THEN 'Other sales' 
					 WHEN 'T' THEN 'Touring' 
					 ELSE 'n/a'
				END AS prd_line,
				CAST(prd_start_dt AS DATE) AS prd_start_dt,
				CAST(
					LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) 
					AS DATE
					) 
					AS prd_end_dt --calculate the end date as one day befor the next start date 
		FROM bronze.crm_prd_info;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST (DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '.................................';

		PRINT '---------------------------------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '---------------------------------------------------------------------';

		-- Loading silver.erp_cust_az12
		SET @start_time = GETDATE();
		PRINT '>> TRUNCATE Table: silver.erp_cust_az12';
		TRUNCATE TABLE silver.erp_cust_az12;
		PRINT '>> Inserting Data Into: silver.erp_cust_az12';

		INSERT INTO silver.erp_cust_az12(
				cid,
				bdate,
				gen
		)
		SELECT 
				CASE 
					  WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4,LEN(cid)) -- Remove 'NAS' prefix if present
					  ELSE cid
				END AS cid, 
				CASE 
					 WHEN bdate > GETDATE() THEN NULL --Set future dates to NULL
					 ELSE bdate
				 END AS bdate,
				 CASE    
					 WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
					 WHEN TRIM(UPPER(gen)) IN ('F', 'FEMALE') THEN 'Female'
					 ELSE 'n/a'
				END gen -- Normalise gender values and handle unknown values
		FROM bronze.erp_cust_az12;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST (DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '.................................'

		-- Loading silver.erp_loc_a101
		SET @start_time = GETDATE();
		PRINT '>> TRUNCATE Table: silver.erp_loc_a101';
		TRUNCATE TABLE silver.erp_loc_a101;
		PRINT '>> Inserting Data Into: silver.erp_loc_a101';

		INSERT INTO silver.erp_loc_a101(
					   cid,
					   cntry
		)
		SELECT 
				REPLACE(cid,'-','') as cid,
				CASE 
						   WHEN TRIM(cntry) IN('US', 'USA', 'United States') THEN 'United States'
						   WHEN TRIM(cntry) IN('UN','United States') THEN 'United Kingdom'
						   WHEN TRIM(cntry) IN('DE', 'Germany') THEN 'Germany'
						   WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
						   ELSE TRIM(cntry)
				END AS cntry
		FROM bronze.erp_loc_a101;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST (DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '.................................'

		-- Loading silver.erp_px_cat_g1v2
		SET @start_time = GETDATE();
		PRINT '>> TRUNCATE Table: silver.erp_px_cat_g1v2';
		TRUNCATE TABLE silver.erp_px_cat_g1v2;
		PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';

		INSERT INTO silver.erp_px_cat_g1v2(
					id,
					cat,
					subcat,
					maintenance
		)
		SELECT 
					id,
					TRIM(cat), 
					TRIM(subcat),
					TRIM(maintenance)
		FROM bronze.erp_px_cat_g1v2;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST (DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '.................................'

		SET @batch_end_time = GETDATE();
		PRINT '=====================================================================';
		PRINT 'Loading Silver Layer Completed'
		PRINT '>> Total Load Duration: ' + CAST (DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '=====================================================================';
	END TRY
	BEGIN CATCH
	   PRINT '=====================================================================';
	   PRINT 'ERROR OCCURED DURING LOADING SILVER LAYER';
	   PRINT 'Error Message' + ERROR_MESSAGE();
	   PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
	   PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
	   PRINT '=====================================================================';
	END CATCH

END 