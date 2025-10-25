CREATE DATABASE home_loans;
USE home_loans;

SHOW TABLES;

/*
-- ------------------------------------------------- Neccessary Adjustments ---------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------

ALTER TABLE sanction_data MODIFY COLUMN full_date datetime;
select YEAR(full_date) FROM sanction_data;


ALTER TABLE `recovery data` RENAME TO recovery_data;
ALTER TABLE recovery_data MODIFY COLUMN full_date datetime;
show columns from recovery_data;
select YEAR(full_date) FROM recovery_data;


show columns from customers;
ALTER TABLE customers MODIFY COLUMN full_date datetime;
select YEAR(full_date) FROM customers;
*/

SHOW COLUMNS FROM branch;
SHOW COLUMNS FROM `channel`;
SHOW COLUMNS FROM customers;
SHOW COLUMNS FROM products;
SHOW COLUMNS FROM recovery_data;
SHOW COLUMNS FROM sanction_data;


/*
-- ------------------------------------------------- TASKS ---------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------
*/

/*----------------------------------------------- Customer Demographics ---------------------------------------*/
-- •	What is the distribution of customers by gender, occupation, age group, and salary bracket?
SELECT gender, COUNT(customer_no) AS Total_Customers FROM customers GROUP BY gender;
SELECT occupation, COUNT(customer_no) AS Total_Customers FROM customers GROUP BY occupation;
SELECT age, COUNT(customer_no) AS Total_Customers FROM customers GROUP BY age;
SELECT salary_bucket, COUNT(customer_no) AS Total_Customers FROM customers GROUP BY salary_bucket;


-- •	What is the average applied loan amount for each occupation?
SELECT occupation, ROUND(AVG(applied_loan_amt), 2) AS Avg_applied_loan FROM customers GROUP BY occupation; 


-- •	Is there a correlation between the age group of a customer and the salary bracket they fall into?
SELECT
	age,
    salary_bucket
FROM customers;


-- •	Which gender applies for higher loan amounts on average?
SELECT gender, ROUND(AVG(applied_loan_amt), 2) AS Avg_applied_loan FROM customers GROUP BY gender ORDER BY Avg_applied_loan DESC LIMIT 1; 


/*----------------------------------------------- Loan Application Analysis ---------------------------------------*/
-- •	What is the distribution of the applied loan amounts?
SELECT 
	MIN(applied_loan_amt) AS Min_Amount,
    MAX(applied_loan_amt) AS Max_Amount,
    ROUND(AVG(applied_loan_amt), 2) AS Avg_Amount,
    COUNT(applied_loan_amt) AS Total_Loan_Amount
FROM customers;

-- •	What is the total number of loan applications received each year and month?
SELECT 
	YEAR(full_date) AS `Year`,
	COUNT(applied_loan_amt) AS Total_Amount
FROM customers
GROUP BY `Year`
ORDER BY `Year`;

SELECT 
    MONTHNAME(full_date) AS `Month`,
	COUNT(applied_loan_amt) AS Total_Amount
FROM customers
GROUP BY `Month`
ORDER BY `Month`;

-- •	Which channel is the most popular for loan applications?
SELECT 
	ch.channels,
    COUNT(*) AS Applications
FROM customers c
JOIN `channel` ch ON ch.`Channel Id` = c.channel_id
GROUP BY ch.channels
ORDER BY Applications DESC LIMIT 1;


-- •	Which product has the highest number of applications?
SELECT 
	p.Products,
    COUNT(*) AS Applications
FROM customers c
JOIN products p ON p.`Product Id` = c.product_id
GROUP BY p.Products
ORDER BY Applications DESC LIMIT 1;



/*----------------------------------------------- Sanction and Disbursal Analysis ---------------------------------------*/
-- •	What is the overall sanction rate (percentage of sanctioned applications out of total applications)?
SELECT 
	(COUNT(DISTINCT s.customer_no) / COUNT(DISTINCT c.customer_no)) * 100 AS Overall_Sanction_Rate
FROM customers c
LEFT JOIN sanction_data s ON s.customer_no = c.customer_no;


-- --------------------------------------------------------------------------------------------------
-- •	What is the average difference between the applied loan amount and the sanctioned amount?
SELECT 
	ROUND(AVG(c.applied_loan_amt - s.sanction_amt), 2) AS Avg_differnce
FROM customers c
JOIN sanction_data s ON s.customer_no = c.customer_no;


-- --------------------------------------------------------------------------------------------------
-- •	What is the average disbursed amount for each product?
SELECT
	p.Products,
	CONCAT("Rs.",ROUND(AVG(s.disb_amt), 2)) AS Avg_Dibursed_Amount
FROM sanction_data s
JOIN customers c ON c.customer_no = s.customer_no
JOIN products p ON p.`Product Id` = c.product_id
GROUP BY p.Products
ORDER BY Avg_Dibursed_Amount DESC;


-- --------------------------------------------------------------------------------------------------
-- •	Which branch has the highest total disbursed loan amount?
SELECT
	b.`Branch Name`,
	ROUND(SUM(s.disb_amt), 2) AS Total_Dibursed_Amount
FROM sanction_data s
JOIN customers c ON c.customer_no = s.customer_no
JOIN branch b ON b.`Branch Code` = c.branch_code
GROUP BY b.`Branch Name`
ORDER BY Total_Dibursed_Amount DESC LIMIT 1;


/*----------------------------------------------- Recovery Analysis ---------------------------------------*/
-- •	What is the distribution of delinquency months?
SELECT 
	`Delinquency Months`,
	COUNT(*) AS Distribution
FROM recovery_data
GROUP BY `Delinquency Months`;


-- --------------------------------------------------------------------------------------------------
-- •	What is the total recovery amount for each branch?
SELECT
	b.`Branch Name`,
	CONCAT("Rs.",ROUND(SUM(r.`Recovery Amount`), 2)) AS Total_Recovery_Amount
FROM recovery_data r
JOIN customers c ON c.customer_no = r.`Customer Number`
JOIN branch b ON b.`Branch Code` = c.branch_code
GROUP BY b.`Branch Name`
ORDER BY Total_Recovery_Amount DESC;


-- --------------------------------------------------------------------------------------------------
-- •	Is there a relationship between the sanctioned amount and the recovery amount?
SELECT
	CONCAT("Rs.", ROUND(AVG(s.sanction_amt), 2)) AS Sanction_Amount,
    CONCAT("Rs.", ROUND(AVG(r.`Recovery Amount`), 2)) AS Recovery_Amount
FROM sanction_data s
JOIN recovery_data r ON r.`Customer Number` = s.customer_no
ORDER BY s.sanction_amt DESC;




-- --------------------------------------------------------------------------------------------------
-- •	What is the average recovery amount for customers with different delinquency months?
SELECT 
	`Delinquency Months`,
	ROUND(AVG(`Recovery Amount`), 2) AS Avg_Recovery_Amount
FROM recovery_data
GROUP BY `Delinquency Months`;



/*----------------------------------------------- Branch and Channel Performance ---------------------------------------*/
-- •	Which branch has the highest number of loan applications?
SELECT
	b.`Branch Name`,
    COUNT(c.applied_loan_amt) AS Applications
FROM customers c 
JOIN branch b ON b.`Branch Code`=c.branch_code
GROUP BY b.`Branch Name`
ORDER BY Applications DESC;


-- --------------------------------------------------------------------------------------------------
-- •	What is the performance of each channel in terms of the number of applications, sanctioned amounts, and recovery amounts?
SELECT
	ch.channels,
    COUNT(c.applied_loan_amt) AS No_Of_Applications,
    CONCAT("Rs.", ROUND(SUM(s.sanction_amt), 2)) AS Sanctioned_Amount,
    CONCAT("Rs.", ROUND(SUM(r.`Recovery Amount`), 2)) AS Recovery_Amount
FROM customers c 
JOIN sanction_data s ON s.customer_no = c.customer_no
JOIN recovery_data r ON r.`Customer Number` = c.branch_code
JOIN `channel` ch ON ch.`Channel Id` = c.channel_id
GROUP BY ch.channels;


-- --------------------------------------------------------------------------------------------------
-- •	Which branch has the highest number of delinquent accounts?
SELECT
	b.`Branch Name`,
	COUNT(r.`Customer Number`) AS Deliquent_Accounts
FROM recovery_data r
JOIN customers c ON c.customer_no = r.`Customer Number`
JOIN branch b ON b.`Branch Code` = c.branch_code
GROUP BY b.`Branch Name`;


-- --------------------------------------------------------------------------------------------------
-- •	What is the geographical distribution of the branches? You can use the latitude and longitude to visualize this.
SELECT
	`Branch Name`, `Branch Longitude`, `Branch Latitute`
FROM branch;



/*----------------------------------------------- Product Performance ---------------------------------------*/
-- •	Which product is the most profitable in terms of sanctioned loan amounts?
SELECT 
	p.Products,
    ROUND(SUM(s.sanction_amt), 2) AS Profitable_Product
FROM products p
JOIN customers c ON c.product_id = p.`Product Id`
JOIN sanction_data s ON s.customer_no = c.customer_no
GROUP BY p.Products
ORDER BY Profitable_Product DESC LIMIT 1;

-- --------------------------------------------------------------------------------------------------
-- •	What is the average applied, sanctioned, and disbursed amount for each product?
SELECT
	p.products,
    ROUND(AVG(c.applied_loan_amt), 2) AS Avg_Applied_Loan_Amount,
    CONCAT("Rs.", ROUND(SUM(s.sanction_amt), 2)) AS Total_Sanctioned_Amount,
    CONCAT("Rs.", ROUND(SUM(s.disb_amt), 2)) AS Total_Disbursed_Amount
FROM customers c 
JOIN sanction_data s ON s.customer_no = c.customer_no
JOIN products p ON p.`Product Id` = c.product_id
GROUP BY p.products;


-- --------------------------------------------------------------------------------------------------
-- •	Which product has the highest delinquency rate?
SELECT
	p.Products,
    CONCAT(ROUND(((COUNT(DISTINCT r.`Customer Number`) / COUNT(DISTINCT c.customer_no))*100), 2), "%") AS deliquency_rate
FROM customers c
LEFT JOIN recovery_data r ON r.`Customer Number` = c.customer_no
JOIN products p ON p.`Product Id` = c.product_id
GROUP BY p.Products;



/*----------------------------------------------- Time Series Analysis---------------------------------------*/
-- •	How has the number of loan applications changed over the years?
SELECT 
	YEAR(full_date) AS `Year`, COUNT(applied_loan_amt) AS Loan_Applications
FROM customers
GROUP BY `Year`
ORDER BY `Year`;


-- --------------------------------------------------------------------------------------------------
-- •	Is there any seasonality in loan applications (e.g., more applications in certain months)?
WITH X AS (
    SELECT 
        YEAR(full_date) AS Years,
        MONTHNAME(full_date) AS Months,
        COUNT(applied_loan_amt) AS Loan_Applications
    FROM customers
    WHERE YEAR(full_date) = 2017
    GROUP BY Years, Months
    ORDER BY Loan_Applications DESC
    LIMIT 1
),
Y AS (
    SELECT 
        YEAR(full_date) AS Years,
        MONTHNAME(full_date) AS Months,
        COUNT(applied_loan_amt) AS Loan_Applications
    FROM customers
    WHERE YEAR(full_date) = 2018
    GROUP BY Years, Months
    ORDER BY Loan_Applications DESC
    LIMIT 1
),
Z AS (
    SELECT 
        YEAR(full_date) AS Years,
        MONTHNAME(full_date) AS Months,
        COUNT(applied_loan_amt) AS Loan_Applications
    FROM customers
    WHERE YEAR(full_date) = 2019
    GROUP BY Years, Months
    ORDER BY Loan_Applications DESC
    LIMIT 1
)
SELECT * FROM X
UNION ALL
SELECT * FROM Y
UNION ALL
SELECT * FROM Z;


-- --------------------------------------------------------------------------------------------------
-- •	How have the sanctioned amounts and recovery amounts trended over time?
SELECT
	YEAR(c.full_date) AS `Year`,
    MONTH(c.full_date) AS `Month`,
    ROUND(SUM(s.sanction_amt), 2) AS Total_Sanction_Amount,
    ROUND(SUM(r.`Recovery Amount`), 2) AS Total_Recovered_Amount
FROM customers c
LEFT JOIN sanction_data s ON s.customer_no = c.customer_no
LEFT JOIN recovery_data r ON r.`Customer Number` = c.customer_no
GROUP BY YEAR(c.full_date), MONTH(c.full_date)
ORDER BY YEAR(c.full_date), MONTH(c.full_date);


/*
-- ------------------------------------------------- TASKS - 2 ---------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------
*/
/*----------------------------------------------- Customer Segmentation and Behavior ---------------------------------------*/
-- •	Risk Profiling by Demographics:
-- o	What is the delinquency rate for different gender, occupation, and age groups?
SELECT
	c.gender, 
    CONCAT(ROUND(((COUNT(DISTINCT r.`Customer Number`) / COUNT(DISTINCT c.customer_no)) * 100), 2), "%") AS deliquency_rate
FROM customers c
LEFT JOIN recovery_data r ON r.`Customer Number` = c.customer_no
GROUP BY c.gender;

-- -------------------------------------------
SELECT 
    c.age, 
    CONCAT(ROUND(((COUNT(DISTINCT r.`Customer Number`) / COUNT(DISTINCT c.customer_no)) * 100), 2), "%") AS deliquency_rate
FROM customers c
LEFT JOIN recovery_data r ON r.`Customer Number` = c.customer_no
GROUP BY c.age;

-- -------------------------------------------
SELECT
    c.occupation, 
    CONCAT(ROUND(((COUNT(DISTINCT r.`Customer Number`) / COUNT(DISTINCT c.customer_no)) * 100), 2), "%") AS deliquency_rate
FROM customers c
LEFT JOIN recovery_data r ON r.`Customer Number` = c.customer_no
GROUP BY c.occupation;
	
	

-- --------------------------------------------------------------------------------------------------
-- o	Is there a correlation between a customer's salary bracket and their likelihood of delinquency?
SELECT
	c.salary_bucket, 
    CONCAT(ROUND(((COUNT(DISTINCT r.`Customer Number`) / COUNT(DISTINCT c.customer_no)) * 100), 2), "%") AS deliquency_rate
FROM customers c
LEFT JOIN recovery_data r ON r.`Customer Number` = c.customer_no
GROUP BY c.salary_bucket;

-- --------------------------------------------------------------------------------------------------
-- •	Product and Channel Preferences:
-- o	Which products are most popular among different occupations?
SELECT 
	c.occupation, 
    p.products,
    COUNT(*) AS Total_Products
FROM customers c
JOIN products p ON p.`Product Id` = c.product_id
GROUP BY c.occupation, p.products
ORDER BY Total_Products DESC;

WITH X AS (
	SELECT 
		c.occupation, 
		p.products,
		COUNT(*) AS Total_Products
	FROM customers c
	JOIN products p ON p.`Product Id` = c.product_id
	WHERE c.occupation = "Salaried"
	GROUP BY c.occupation, p.products
	ORDER BY Total_Products DESC LIMIT 1
),
Y AS (
	SELECT 
		c.occupation, 
		p.products,
		COUNT(*) AS Total_Products
	FROM customers c
	JOIN products p ON p.`Product Id` = c.product_id
    WHERE c.occupation = "Business"
	GROUP BY c.occupation, p.products
	ORDER BY Total_Products DESC LIMIT 1
)
SELECT * FROM X 
UNION ALL 
SELECT * FROM y;


-- --------------------------------------------------------------------------------------------------
-- o	Do customers from different salary brackets prefer different products or channels?
SELECT
	c.salary_bucket, ch.`channels`,
    p.products,
    COUNT(c.customer_no) AS Total_Customers
FROM customers c
JOIN products p ON p.`Product Id` = c.product_id
JOIN `channel` ch ON ch.`Channel Id` = c.channel_id
GROUP BY c.salary_bucket, p.Products, ch.`Channels`
ORDER BY c.salary_bucket, p.Products, ch.`channels`;


-- --------------------------------------------------------------------------------------------------
-- o	What is the average loan amount requested through each channel?
SELECT
	ch.channels,
    ROUND(AVG(c.applied_loan_amt), 2) AS Avg_Loan_Requested
FROM customers c
JOIN `channel` ch ON ch.`Channel Id` = c.channel_id
GROUP BY ch.channels
ORDER BY Avg_Loan_Requested DESC;



/*----------------------------------------------- Sanction Rate Analysis ---------------------------------------*/
-- o	How does the sanction rate vary across different branches?
SELECT
	b.`Branch Name`,
    CONCAT(ROUND((COUNT(DISTINCT s.customer_no) / COUNT(DISTINCT c.customer_no))*100, 2), "%") AS Sanction_Rate
FROM customers c
LEFT JOIN sanction_data s ON s.customer_no = c.customer_no
JOIN branch b ON b.`Branch Code` = c.branch_code
GROUP BY b.`Branch Name`;


-- --------------------------------------------------------------------------------------------------
-- o	Is there a difference in the sanction rate for different occupations or salary brackets?
SELECT
	c.occupation,
	(COUNT(s.customer_no) / COUNT(c.customer_no))*100 AS Sanction_Rate
FROM customers c 
JOIN sanction_data s ON s.customer_no = c.customer_no
GROUP BY c.occupation;


SELECT
	c.salary_bucket,
	(COUNT(s.customer_no) / COUNT(c.customer_no))*100 AS Sanction_Rate
FROM customers c 
JOIN sanction_data s ON s.customer_no = c.customer_no
GROUP BY c.salary_bucket;


-- --------------------------------------------------------------------------------------------------
-- o	What is the average percentage of the applied loan amount that gets sanctioned for different products?
SELECT
	p.Products,
    ROUND((AVG(s.sanction_amt / c.applied_loan_amt) * 100), 2) AS Avg_Sanction_Pct
FROM customers c
JOIN sanction_data s ON s.customer_no = c.customer_no
JOIN products p ON p.`Product Id` = c.product_id
GROUP BY p.Products;


-- --------------------------------------------------------------------------------------------------
-- •	Delinquency Analysis:
-- o	Is there a relationship between the channel through which a loan was sourced and the likelihood of delinquency?
SELECT
	ch.`Channels`,
    CONCAT(ROUND(((COUNT(DISTINCT r.`Customer Number`) / COUNT(DISTINCT c.customer_no)) * 100), 2), "%") AS deliquency_rate
FROM customers c 
LEFT JOIN recovery_data r ON r.`Customer Number` = c.customer_no
JOIN `channel` ch ON ch.`Channel Id` = c.channel_id
GROUP BY ch.`Channels`;
    

-- --------------------------------------------------------------------------------------------------
-- o	Do customers who take Loans + Top-up have a higher or lower delinquency rate compared to other products?
SELECT 
	p.Products,
    CONCAT(ROUND((COUNT(DISTINCT r.`Customer Number`) / COUNT(DISTINCT c.customer_no)) * 100, 2), "%") AS Deliquency_Rate
FROM customers c 
JOIN products p ON p.`Product Id` = c.product_id
LEFT JOIN recovery_data r ON r.`Customer Number` = c.customer_no
GROUP BY p.Products
HAVING p.Products LIKE '%Loans%'OR p.Products LIKE '%Top-up%'
;


-- --------------------------------------------------------------------------------------------------
-- o	What is the average time to the first delinquency for each branch?
SELECT 
	b.`Branch Name`,
    CONCAT(ROUND((AVG(DATEDIFF(c.full_date, r.full_date))*100), 2),  " ", "Days") AS Avg_Time_First_deliquency
FROM customers c
JOIN recovery_data r ON r.`Customer Number` = c.customer_no
JOIN branch b ON b.`Branch Code` = c.branch_code
GROUP BY b.`Branch Name`;



/*----------------------------------------------- Operational and Business Questions ---------------------------------------*/
-- •	Geospatial Analysis:
-- o	Which branches have the highest concentration of high-value loans (based on sanctioned amount)?
SELECT
	b.`Branch Name`,
    CONCAT("Rs.", " ", ROUND(SUM(s.sanction_amt), 2)) AS High_Value_Loans
FROM customers c 
JOIN branch b ON b.`Branch Code` = c.branch_code
JOIN sanction_data s ON s.customer_no = c.customer_no
GROUP BY b.`Branch Name`
ORDER BY High_Value_Loans DESC;


-- o	Is there a geographical pattern to delinquency? Are certain regions or branches more prone to defaults?
SELECT
	b.`Branch Name`,
    b.`Branch Longitude`,
    b.`Branch Latitute`,
    COUNT(r.`Customer Number`) AS deliquency
FROM customers c 
JOIN branch b ON b.`Branch Code` = c.branch_code
JOIN recovery_data r ON r.`Customer Number` = c.customer_no
GROUP BY b.`Branch Name`, b.`Branch Longitude`, b.`Branch Latitute`;


-- --------------------------------------------------------------------------------------------------
-- •	Cross-selling and Upselling:
-- o	What percentage of customers opt for bundled products like Loans + Group Insurance or Loans + Individual Insurance?
WITH X AS (
	SELECT 
		COUNT(customer_no) AS Bundled_Customers
	FROM customers c
    JOIN products p ON p.`Product Id` = c.product_id
    WHERE Products LIKE '%+%'
)
SELECT 
	CONCAT(ROUND((Bundled_Customers / (SELECT COUNT(customer_no) FROM customers)) * 100, 2),
			" ",
			"%") AS Bundled_Pct
FROM X;


-- o	Is there a demographic pattern (e.g., age, occupation) among customers who choose these bundled products?
SELECT 
	c.age,
	COUNT(c.customer_no) AS Bundled_Customers
FROM customers c
JOIN products p ON p.`Product Id` = c.product_id
WHERE p.Products LIKE '%+%'
GROUP BY c.age;
-- -----------------------------------------------------
SELECT 
	c.occupation,
	COUNT(c.customer_no) AS Bundled_Customers
FROM customers c
JOIN products p ON p.`Product Id` = c.product_id
WHERE p.Products LIKE '%+%'
GROUP BY c.occupation;
-- --------------------------------------------------------
SELECT 
	c.gender,
	COUNT(c.customer_no) AS Bundled_Customers
FROM customers c
JOIN products p ON p.`Product Id` = c.product_id
WHERE p.Products LIKE '%+%'
GROUP BY c.gender;



/*----------------------------------------------- Profitability Analysis:---------------------------------------*/
-- o	Which branch or product has the highest ratio of total recovered amount to total disbursed amount? (This can be a proxy for profitability, 
-- 		though it doesn't account for interest).
SELECT p.Products,
       ROUND(SUM(r.`Recovery Amount`) / SUM(s.disb_amt), 2) AS recovery_to_disbursed_ratio
FROM sanction_data s
JOIN recovery_data r ON s.customer_no = r.`Customer Number`
JOIN customers c ON s.customer_no = c.customer_no
JOIN products p ON c.product_id = p.`Product Id`
GROUP BY p.Products
ORDER BY recovery_to_disbursed_ratio DESC;



-- --------------------------------------------------------------------------------------------------
-- o	What is the average (Sanctioned Amount - Disbursed Amount) for each product, and what does this tell you about fees or other charges?
SELECT
	p.Products,
    ROUND(AVG(s.sanction_amt - s.disb_amt), 2) AS Avg_Fees_Buffer
FROM customers c
JOIN products p ON p.`Product Id` = c.product_id
JOIN sanction_data s ON s.customer_no = c.customer_no
GROUP BY p.Products;













