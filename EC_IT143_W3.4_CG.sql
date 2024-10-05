/*****************************************************************************************************************
NAME:    EC_IT143_W3.4_CG
PURPOSE: Solve marginal, moderate, increased complexity, and metadate questions using SQL queries

MODIFICATION LOG:
Ver      Date        Author         Description
-----   ----------   -----------    -------------------------------------------------------------------------------
1.0     05/23/2022   JJAUSSI        1. Built this script for EC IT440
2.0	    05/11/2024	 Chino Guerrero 1. Modified for 3.4 Adventure Works-Create Answers assignment


RUNTIME: 
0m 3s (Actual execution time)

NOTES: 
Built for the 3.4 Adventure Works-Create Answers assignment

Resources used: 
- 3.4 Adventure Works-Create Answers
- https://dataedo.com/samples/html/AdventureWorks/doc/AdventureWorks_2/modules/Sales_12/tables/Sales_SalesOrderDetail_184.html
- 
 
******************************************************************************************************************/

-- Q1: How many unique cities have interacted with our company according to our records? (Chino Guerrero)
-- Reworked question: How many unique cities have a transaction history in our records?
-- Step 1) Look through the SalesOrderHeader for customer transaction history
-- Step 2) Combine the information with Customer which has their information
-- Step 3) Add information from BusinessEntityAddress to find coresponding Address IDs
-- Step 4) Locate the unique citites in Address
-- A1: AdventureWorks has had transactions with 274 unique citites.

SELECT COUNT(DISTINCT addr.City) AS UniqueCityTransactionCount
		FROM Sales.SalesOrderHeader soh
		JOIN Sales.Customer cust
		  ON soh.CustomerID = cust.CustomerID
		JOIN Person.BusinessEntityAddress bea
		  ON cust.PersonID = bea.BusinessEntityID
		JOIN Person.Address addr
		  ON bea.AddressID = addr.AddressID;

-- Q2: How many employees are currently working in the Sales department? (Alexis Fox)
-- Reworked question: How many employees are there in Sales?
-- Step 1) Look through the HumanResources.Employee table for BusinessIDs
-- Step 2) Combine with EmployeeDepartmentHistory to see who is employed
-- Step 3) Isolate the Sales department with the Department table
-- Step 4) Indicate that we only need current employees returned
-- A2: 18

SELECT COUNT(DISTINCT emp.BusinessEntityID) AS SalesEmployeeCount
		FROM HumanResources.Employee emp
		JOIN HumanResources.EmployeeDepartmentHistory edh
		  ON emp.BusinessEntityID = edh.BusinessEntityID
		JOIN HumanResources.Department dep
		  ON edh.DepartmentID = dep.DepartmentID
	   WHERE dep.Name = 'Sales'
		 AND edh.EndDate IS NULL; -- Having no end date means they are currently employed

-- Q3: We are suspiciously over budget. Return our top 50 most expensive transactions according to actual cost. What are their ProductIDs and their standard cost as recorded in the product cost history? (Chino Guerrero)
--Reworked question: What are the top 50 most expensive actual cost transactions, and what are their ProductIDs and standard cost?
-- Step 1) Indicate we only want 50 results
-- Step 2) Grab all the productIDs from SalesOrderDetail
-- Step 3) There isn't a column exactly named "actual cost" but "line cost is described as the subtotal per product. (See https://dataedo.com/samples/html/AdventureWorks/doc/AdventureWorks_2/modules/Sales_12/tables/Sales_SalesOrderDetail_184.html)
-- Step 4) Alias LineTotal as ActualCost
-- Step 5) Grab the total cost of transaction per product
-- Step 6) Grab the standard costs from the ProductCostHistory table
-- Step 7) Combine the Production.Product and Production.ProductCostHistory tables
-- Step 8) Add the condition to only return recent standard costs for products according to startdate
-- Step 9) Dictate the sequence of the actual cost to show the most expensive ones first
-- Step 10 optional) Add the currency sign to actual and standard cost by formatting 
-- A3: See results

SELECT TOP 50
    sod.ProductID,
    FORMAT(sod.LineTotal, 'C', 'en-US') AS ActualCost,
    FORMAT(pch.StandardCost, 'C', 'en-US') AS StandardCost
	FROM Sales.SalesOrderDetail sod
	JOIN Production.Product p
      ON sod.ProductID = p.ProductID
	JOIN Production.ProductCostHistory pch
      ON p.ProductID = pch.ProductID
	WHERE pch.StartDate = (
        SELECT MAX(StartDate) 
        FROM Production.ProductCostHistory 
        WHERE ProductID = p.ProductID
    )
ORDER BY sod.LineTotal DESC;


-- Q4:  I want to know which employees have made more than 100 sales in a month. Which employees exceeded this threshold in July 2021? (Danilo C. Ymbong)
-- This database does not have information beyond 2019, so we will not find any results from 2021
-- Instead we will prioritize finding employees with over 100 sales with a wider window 
-- Restated question: Which employees had over 100 sales transactions from July 2011 to July 2015?
-- Step 1) Indicate that we want the ID, first name, and last name returned to us
-- Step 2) Indicate that we're looking for total sales from these employees
-- Step 3) Find these pieces of information from the HumanResources.Employee table
-- Step 4) Combine the SalesOrderHeader and the SalesPersonID
-- Step 5) Add a condition to return sales from July 2021 only
-- Step 6) Add instruction to group returns by ID, first name, and last name
-- Step 7) Add a condition that only returns info form employees that have over 100 sales
-- A4: See results

SELECT e.BusinessEntityID,
	   p.FirstName,
       p.LastName,
 COUNT(soh.SalesOrderID) AS TotalSales
  FROM HumanResources.Employee e
  JOIN Person.Person p
    ON e.BusinessEntityID = p.BusinessEntityID
  JOIN Sales.SalesOrderHeader soh
    ON e.BusinessEntityID = soh.SalesPersonID -- Assuming SalesPersonID ties employees to sales orders
  WHERE 
    soh.OrderDate >= '2011-07-01' AND 
    soh.OrderDate < '2015-08-01'   
GROUP BY e.BusinessEntityID, 
		 p.FirstName, 
		 p.LastName
HAVING 
    COUNT(soh.SalesOrderID) > 100;


-- Q5: Over the last year, we have increased the salary of some sales employees and others have not benefited. Amongst those that their salary have not been increased, please find me the best 5 employees based on their sales record. (Precious Okechukwu)
-- Restated question: Who are 5 employees with the highest sales whose salary has not increased in 2013?
-- Step 1) Use the SalesOrderheader table to find out the total sales for employees 
-- Step 2) From that table, isolate thos employees whose salary did not change in 2013
-- Step 3) Select the top 5 employees based on that information
-- A5: Linda Mitchell, Jae Pak, Michael Blythe, Jilian Carson, and Ranjit Vakrey Chudukati has not had a salary raise but have the highest sales

WITH SalesSummary AS (
    SELECT 
        soh.SalesPersonID AS EmployeeID,
        SUM(soh.TotalDue) AS TotalSales
    FROM Sales.SalesOrderHeader soh
    WHERE YEAR(soh.OrderDate) = 2013  -- Filter sales for 2013
 GROUP BY soh.SalesPersonID
),

NoSalaryIncrease AS (
    SELECT 
        eph.BusinessEntityID AS EmployeeID,
        MAX(eph.RateChangeDate) AS LastSalaryChange
      FROM HumanResources.EmployeePayHistory eph
  GROUP BY eph.BusinessEntityID
      HAVING MAX(eph.RateChangeDate) < '2013-01-01' OR MAX(eph.RateChangeDate) > '2013-12-31'
)

SELECT TOP 5 
    p.FirstName,
    p.LastName
FROM SalesSummary ss
JOIN NoSalaryIncrease nsi
  ON ss.EmployeeID = nsi.EmployeeID
JOIN HumanResources.Employee e
  ON e.BusinessEntityID = ss.EmployeeID
JOIN Person.Person p
  ON p.BusinessEntityID = e.BusinessEntityID
ORDER BY ss.TotalSales DESC; 

-- Q6: I am reviewing sales performance for the year 2012. Can you provide a summary of total sales by month for all product categories? I need the total quantity sold, list price, and standard cost for each month. (Hunter Robinson)
-- Restated question: In the year 2021, what are the total sales of all product categories by month and their total quantity sold, as well as the list price and standard cost for each month.
-- Step 1) Gather the SalesMonth information
-- Step 2) Compute the order quantity
-- Step 3) Compute the average list price 
-- Step 4) Compute the average standard cost 
-- Step 5) Group and order by salesmonth
-- A6: See results

SELECT 
    MONTH(soh.OrderDate) AS SalesMonth,  -- Extract month from OrderDate
    pc.Name AS ProductCategory,
    SUM(sod.OrderQty) AS TotalQuantitySold,  -- Total quantity sold for the month
    FORMAT(AVG(p.ListPrice), 'C', 'en-US') AS ListPrice,  -- Average list price formatted as currency
    FORMAT(AVG(p.StandardCost), 'C', 'en-US') AS StandardCost  -- Average standard cost of products sold
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
WHERE 
    YEAR(soh.OrderDate) = 2012  -- Filter for the year 2012
GROUP BY 
    MONTH(soh.OrderDate),  -- Group results by month
    pc.Name
ORDER BY 
    SalesMonth,  -- Order results by month and product category
    ProductCategory; 

-- Q7: What are the data types of the columns in the HumanResources.Employee table? (Ezra Amankwaa)
-- Step 1) Indicate that we want the column name and its data type from INFORMATION_SCHEMA.COLUMNS
-- Step 2) Specify that we only want results from the HumanResources.Employee table.
-- A7: See results

SELECT 
    COLUMN_NAME AS ColumnName, 
    DATA_TYPE AS DataType
FROM 
    INFORMATION_SCHEMA.COLUMNS
WHERE 
    TABLE_NAME = 'Employee' AND 
    TABLE_SCHEMA = 'HumanResources'; 

-- Q8: What are the names and data types of all the columns in the Person table? (Percy Yarleque Jara)
-- Step 1) Gather all the column names and data types from the information_schema.columns system view and give an ailas
-- Step 2) Refine the resultes to only return tables from person
-- A8: See results

SELECT 
    COLUMN_NAME AS ColumnName, 
    DATA_TYPE AS DataType
FROM 
    INFORMATION_SCHEMA.COLUMNS
WHERE 
    TABLE_NAME = 'Person'; 