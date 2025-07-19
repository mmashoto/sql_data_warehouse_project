/*
================================================================================
CREATE DATABASE AND SCHEMAS
================================================================================
Script Purpose:
       This script creates a new database called 'DataWarehouse' after checking if it already exists.
	   If the database exists, it will be dropped and recreated. Additionally, the script sets up the 
	   schemas within the database: 'bronze','silver','gold'.

WARNING
      Running this script will drop the entire 'DataWarehouse' database if it exists.
	  All data in the database will consequently be deleted (permanently). Proceed with caution 
	  and ensure you have proper backups before running this script.
*/



USE master;
GO
--'GO' is a separator (it will initially execute the complete command and then move on the second one)

--drop and recreate the database 'Datawarehouse'
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
      ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE
	  DROP DATABASE DataWarehouse;
END;

GO

-- create the 'DataWarehouse' database 
CREATE DATABASE DataWarehouse;
GO


--switch to the newly created 'DataWarehouse'database 
USE DataWarehouse;
GO


--create schemas (a schema is essentially a folder or container that assists in keeping things organized in a database)
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO

