/* What are the top 5 brands by sales among users that have had their account for at least six months?

   Breaking things up to CTEs to make it easier to read and explain
   User_Account_6_Months - Get the users that have had their account for at least 6 months based on CREATED_DATE */
WITH User_Account_6_Months AS (
        SELECT ID
        FROM users
        WHERE DATE_DIFF('month', CAST(CREATED_DATE AS DATE), CURRENT_DATE) >= 6
    ),
/* Filered_Transactions - Filter the transactions based on the users that have had their account for at least 6 months, which was found on the previous CTE
   Need to convert FINAL_SALE to Double, because we can not sum a varchar */
    Filtered_Transactions AS (
        SELECT t.RECEIPT_ID
             , t.BARCODE
             , u.ID
             , CAST(t.FINAL_SALE AS DOUBLE) AS FINAL_SALE
        FROM Transactions t
        JOIN User_Account_6_Months u ON t.user_ID = u.ID
    )
/*  Sum of FINAL_SALE to get the total sales for each brand
    Group by brand to get the total sales for each brand
    Order by total sales in descending order and then limit to 5 to get the top 5 brands */
    SELECT p.BRAND
         , SUM(f.FINAL_SALE) AS total_sales
    FROM Filtered_Transactions f
    JOIN products p ON f.BARCODE = p.BARCODE
    GROUP BY p.BRAND
    ORDER BY total_sales DESC
    LIMIT 5;

/* Among users who have had their accounts for over six months, CVS leads in total sales, bringing in $72.00, more than double that of DOVE ($30.91) in second place. 
   TRIDENT ($23.36), COORS LIGHT ($17.48), and TRESEMMÉ ($14.58) round out the Top 5. We can see 3 of the 5 as Health  & Wellness category, while the other 2 are Snacks and Alcohol respectively. 
   
   If I were to create a dashboard/chart of this insight, I would create a bar chart that allows the stakeholders to easily and clearly see the total sales by each brand. */



/* What is the percentage of sales in the Health & Wellness category by generation?
   Breaking things up to CTEs to make it easier to read and explain 

   User_Generation_Categorization - Categorize the users into different generations based on their age 
   According to Beresford Research, in 2025, Gen Alpha is from age 0-12, Gen Z is from 13-28, Millennials is from 29-44, Gen X is from 45-60, Baby Boomers is from 61 - 79, Post War is from 80 - 97, and WWII is from 98-103 
   In order to do this, I use CASE statements and only used the years of their birthdate to make this more generalized*/
WITH User_Generation_Categorization AS (
    SELECT ID,
           CASE 
               WHEN DATE_DIFF('year', CAST(BIRTH_DATE AS DATE), CURRENT_DATE) BETWEEN 0 AND 12 THEN 'Gen Alpha'               
               WHEN DATE_DIFF('year', CAST(BIRTH_DATE AS DATE), CURRENT_DATE) BETWEEN 13 AND 28 THEN 'Gen Z'
               WHEN DATE_DIFF('year', CAST(BIRTH_DATE AS DATE), CURRENT_DATE) BETWEEN 29 AND 44 THEN 'Millennials'
               WHEN DATE_DIFF('year', CAST(BIRTH_DATE AS DATE), CURRENT_DATE) BETWEEN 45 AND 60 THEN 'Gen X'
               WHEN DATE_DIFF('year', CAST(BIRTH_DATE AS DATE), CURRENT_DATE) BETWEEN 61 AND 79 THEN 'Baby Boomers'
               WHEN DATE_DIFF('year', CAST(BIRTH_DATE AS DATE), CURRENT_DATE) BETWEEN 80 AND 97 THEN 'Post War'               
               WHEN DATE_DIFF('year', CAST(BIRTH_DATE AS DATE), CURRENT_DATE) BETWEEN 98 AND 103 THEN 'WWII'
               ELSE 'Other'
           END AS generation
    FROM users
),

/* Total_Sales_Health - Get the total sales for the Health & Wellness category by generation
   Need to convert FINAL_SALE to Double, because we can not sum a varchar 
   Also checked that the value HEALTH & WELLNESS is only in CATEGORY_1*/
Total_Sales_Health AS (
    SELECT u.generation
         , SUM(CAST(t.FINAL_SALE AS DOUBLE)) AS total_health_sales
    FROM transactions t
    JOIN User_Generation_Categorization u ON t.user_ID = u.ID
    JOIN products p ON t.BARCODE = p.BARCODE
    WHERE p.CATEGORY_1 = 'HEALTH & WELLNESS'
    GROUP BY u.generation
),

/* Total_Sales_All_Categories - Get the total sales for all categories by generation
   Need to convert FINAL_SALE to Double, because we can not sum a varchar */
Total_Sales_All_Categories AS (
    SELECT u.generation
         , SUM(CAST(t.FINAL_SALE AS DOUBLE)) AS total_all_sales
    FROM transactions t
    JOIN User_Generation_Categorization u ON t.user_ID = u.ID
    GROUP BY u.generation
)
/* Joined the 2 CTEs on generation to get the total sales for Health & Wellness and total sales for all categories by generation
   Calculated the percentage of sales in the Health & Wellness category by generation */
SELECT h.generation
     , h.total_health_sales
     , c.total_all_sales 
     , ROUND((h.total_health_sales / c.total_all_sales) * 100, 2) AS health_sales_percentage
FROM Total_Sales_Health h
JOIN Total_Sales_All_Categories c ON h.generation = c.generation;

/* Baby Boomers lead in Health & Wellness spending with $84.09, making up 37.32% of their total purchases ($225.30). 
   Gen X follows, spending $37.81 on Health & Wellness, which accounts for 22.36% of their $169.13 total spend. 
   Millennials, despite having $189.61 in total purchases, allocate only 18.55% ($35.17) to Health & Wellness. 
   This trend suggests that older generations are spending more on the Health & Wellness category, while younger consumers focus more on other categories. 
   This insight can help us tailor product offerings and marketing strategies to specific generations based on their buying behaviors. 
   
   If I were to create a dashboard/chart for this insight, I would create a stacked bar chart that shows both the health sales and total sales for each generation.
   I would also create a line chart of the health sales and total sales comparison over birth years and see if there are any interesting results there. */



/* Which is the leading brand in the Dips & Salsa category?
   
   Assuming that final sales is the revenue, and final quantity is the quantity sold, and count_receipts is the number of transactions
   I will be using these 3 metrics to determine the leading brand in the Dips & Salsa category 
   
   Need to convert FINAL_SALE to Double, because we can not sum a varchar
   Count the receipts is the number of transactions. This will be distinct as receipt_id is unique for each transaction.
   Checked that the value DIPS & SALSA is only in CATEGORY_2. Also added a condition that the BRAND is not null as this could be multiple brands sharing the same aggregations
   Group by brand to get all the aggregations for each brand */
SELECT p.BRAND
     , SUM(CAST(t.FINAL_SALE AS DOUBLE)) AS total_sales
     , SUM(CAST(t.FINAL_QUANTITY AS DOUBLE)) AS total_quantity
     , COUNT(RECEIPT_ID) as count_receipts

FROM transactions t
JOIN products p ON t.BARCODE = p.BARCODE
WHERE p.CATEGORY_2 = 'DIPS & SALSA'
AND p.BRAND IS NOT NULL
GROUP BY p.BRAND
ORDER BY total_sales DESC
       , total_quantity DESC
       , count_receipts DESC
LIMIT 3;


/* TOSTITOS is the clear leader in the Dips & Salsa category, generating $181.30 in total sales with 38 units sold across 36 transactions, making it both the highest-grossing and most frequently purchased brand. 
   It significantly outperforms GOOD FOODS ($94.91, 9 units) and PACE ($79.73, 22 units), which rank second and third, respectively, in both revenue and purchase volume, further solidifying its dominance in the category. 
   
   If I were to create a dashboard/chart for this insight, I would create a triple bar chart that has the three aggregations broken down by each brand, so the stakeholders can see the differences easily. 
   If one of the metrics is of a higher priority, then I would do a normal bar chart to make things less confusing for the stakeholders. */