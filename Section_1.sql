/* Set up the Users Table so that the columns are correctly named
   Renaming the Column names based on the first row in the csv */

ALTER TABLE Users RENAME COLUMN column0 TO ID;
ALTER TABLE Users RENAME COLUMN column1 TO CREATED_DATE;
ALTER TABLE Users RENAME COLUMN column2 TO BIRTH_DATE;
ALTER TABLE Users RENAME COLUMN column3 TO STATE;
ALTER TABLE Users RENAME COLUMN column4 TO LANGUAGE;
ALTER TABLE Users RENAME COLUMN column5 TO GENDER;

-- Deleting the column name row

DELETE FROM Users WHERE ID = 'ID'; 

/* Cleaning Users Table

   Assuming that the columns have the correct data type
   Checked if ID is non-NULL and unique, and it is */

SELECT * FROM Users
WHERE ID IS NULL;

SELECT ID
     , COUNT(*) 
FROM Users 
GROUP BY ID 
HAVING COUNT(*) > 1;

/* To make things more readable, changing language code to language name based on google
   Already checked if there are more code, but there wasn't */

UPDATE Users
SET LANGUAGE = CASE 
        WHEN LANGUAGE = 'en' THEN 'ENGLISH'
        WHEN LANGUAGE = 'es-419' THEN ' Latin American Spanish'
    ELSE 'UNKNOWN'
END;

/* Wanted to fill in the NULLs for BIRTH_DATE and saw that the oldest birth date is 1900-01-01 00:00:00.000 Z
   I assume that these rows are also placeholders, because this is a common placeholder for unknown dates */

SELECT min(BIRTH_DATE)
FROM Users;

SELECT *
FROM Users
WHERE BIRTH_DATE LIKE '%1900-01-01%';

/* Standardize STATE, LANGUAGE, and GENDER to make it all uppercase
   Depending on stakeholders, we might be adding values to NULLs, but in this case, we will leave it as is*/

UPDATE Users
SET 
    STATE = UPPER(STATE),
    LANGUAGE = UPPER(LANGUAGE),
    GENDER = UPPER(GENDER);





/* Cleaning Products Table
  
   Assuming that the columns have the correct data type
   Assuming that BARCODE is the product ID 
   This means that it has to be non-NULL and unique */

DELETE FROM Products WHERE BARCODE IS NULL;

-- Randomly checking one duplicate to get some insights
SELECT BARCODE
     , COUNT(*) 
FROM Products 
GROUP BY BARCODE 
HAVING COUNT(*) > 1;

SELECT *
FROM Products
WHERE BARCODE = 3409800;

/* Assuming this Products table is meant to be some kind of product lookup table, I will remove any duplicate barcodes 
   Since every column is also a duplicate, we can just keep one row */

DELETE FROM Products
WHERE BARCODE IN (SELECT BARCODE 
                  FROM (SELECT BARCODE
                             , ROW_NUMBER() OVER (PARTITION BY BARCODE) AS row_num
                        FROM products) 
                  WHERE row_num > 1);

/*  Assuming that the condition for a valid barcode is that it is numeric 
    The following query checks if there are any barcode that is not numeric. Since it returns NULL, we know that every BARCODE is numeric */
SELECT BARCODE
FROM Products
WHERE BARCODE LIKE '%[^0-9]%';

-- Assuming that there is a standard for the length of a BARCODE

SELECT DISTINCT LENGTH(BARCODE) AS barcode_length
              , COUNT(*)        AS num_barcode
FROM Products
GROUP BY 1;

/*  From this distribution, I assume that the standard is 11 - 13 numbers
    Therefore, I will be removing the outliers, which barcodes that are not in those numbers */

DELETE FROM Products WHERE LENGTH(BARCODE) NOT IN (11,12,13);

/*  Depending on the situation, project, or use case, I would ask Product/Engineering what the context of the other columns are. 
    From there, I would decide to make the filters more strict or start filtering the other columns.
    In this case, I assume that the other columns are optional 
    I will standardize the remaining columns to make it all uppercase
    This is to make the dashboard and charts more clear and easier to understand */

UPDATE Products
SET CATEGORY_1 = UPPER(CATEGORY_1),
    CATEGORY_2 = UPPER(CATEGORY_2),
    CATEGORY_3 = UPPER(CATEGORY_3),
    CATEGORY_4 = UPPER(CATEGORY_4),
    MANUFACTURER = UPPER(MANUFACTURER),
    BRAND = UPPER(BRAND);





/*  Cleaning Transactions Table
    
    Assuming that the columns have the correct data type
    Checked if ID is non-NULL and unique, and it is non-NULL, but not unique
    After checking a few uniques, it looks like every coluimn, except the FINAL_QUANTITY and FINAL_SALE
    This is a data discrepancy issue. In this case, I will just take the max value of those columns to deduplicate the primary key.
    Again depending on the situation, I would ask Product/Engineering for more context to debug. */

SELECT * 
FROM Transactions
WHERE RECEIPT_ID IS NULL;

SELECT RECEIPT_ID
     , COUNT(*) 
FROM Transactions 
GROUP BY RECEIPT_ID 
HAVING COUNT(*) > 1;

/*  Doing the Standardizing code first before we debug so that it will be more clear and understandable
    Standardizing FINAL_QUANTITY from 'zero' to 0  */

UPDATE Transactions
SET FINAL_QUANTITY = 
    CASE 
        WHEN FINAL_QUANTITY = 'zero' THEN 0
        ELSE FINAL_QUANTITY
    END;

/*  Starting the debug of the duplicate RECEIPT_ID data discrepancy issue.
    Again depending on the situation, I would ask Product/Engineering for more context to debug.
    In this case, I will just take the max value of both FINAL_QUANTITY and FINAL_SALE to deduplicate the primary key.

   So I will be going to tackle this in a very roundabout way due to the limitation of the editor
   Basically, I will be creating a copy of the Transactions table but it will have row_number as a new column.
   Then I will be manipulating that temp table to drop the duplicates and then replacing the original Transactions table with it. */

CREATE TABLE Temp_transactions AS
SELECT * 
     , ROW_NUMBER() OVER (PARTITION BY RECEIPT_ID ORDER BY FINAL_QUANTITY DESC, FINAL_SALE DESC) AS row_num
FROM Transactions;

DELETE FROM Temp_transactions WHERE row_num > 1;

ALTER TABLE Temp_transactions DROP COLUMN row_num;

DROP TABLE Transactions;

ALTER TABLE Temp_transactions RENAME TO Transactions;