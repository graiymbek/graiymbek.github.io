-- ============================================================
-- Retail Sales Analytics — SQL
-- SQL Server (T-SQL).
--
-- This dashboard was originally built a few years ago while
-- working through a Power BI course (Maven Analytics, via Udemy)
-- — the source data's exact origin isn't known, so as with
-- Healthcare there's no "PART 1: build the star schema" section;
-- these are analytical queries written directly against the real
-- source tables, mirroring the DAX measures used across the
-- report's four pages (Exec Dashboard, Product Detail, Customer
-- Detail, Map).
--
-- Real tables used below: Sales Data (fact), Returns Data,
-- Customer Lookup, Product Lookup, Product Subcategories Lookup,
-- Categories Lookup, Territory Lookup, Calendar Lookup.
--
-- A few tables in the model are course-demo scaffolding rather
-- than real analytical data — "Customer Metric Selection",
-- "Product Metric Selection", "Price Adjustment(%)", and
-- "Product Category Sales (Unpivot Demo)" are Power BI teaching
-- features (dynamic metric switching, What-if parameters, an
-- unpivot example) and are intentionally left out of the SQL below.
--
-- Note: the fact table (Sales Data) doesn't carry a revenue amount
-- directly — the DAX measure is literally named
-- "Total Revenue using_sumx", i.e. computed row-by-row as
-- OrderQuantity × ProductPrice. The SQL below mirrors that with a
-- join to Product Lookup + SUM, which is the set-based equivalent.
--
-- "Revenue Target" / "order target" / "profit target" aren't
-- included — there's no separate targets table in this model, so
-- those look like fixed values configured directly in Power BI
-- (or driven by the What-if parameter above) rather than something
-- derived from the transactional data.
-- ============================================================


-- ============================================================
-- EXEC DASHBOARD
-- ============================================================

-- Headline KPIs
SELECT
    SUM(s.OrderQuantity * p.ProductPrice)                         AS Total_Revenue,
    SUM(s.OrderQuantity * (p.ProductPrice - p.ProductCost))       AS Total_Profit,
    COUNT(DISTINCT s.OrderNumber)                                  AS Total_Orders,
    COUNT(DISTINCT s.CustomerKey)                                  AS Total_Customers,
    SUM(s.OrderQuantity * p.ProductPrice)
        / NULLIF(COUNT(DISTINCT s.CustomerKey), 0)                 AS Avg_Revenue_Per_Customer,
    (SELECT SUM(ReturnQuantity) FROM [Returns Data]) * 1.0
        / NULLIF(SUM(s.OrderQuantity), 0)                          AS Return_Rate_Pct
FROM [Sales Data] s
JOIN [Product Lookup] p ON p.ProductKey = s.ProductKey;
GO

-- Monthly revenue trend
SELECT
    DATEFROMPARTS(YEAR(s.OrderDate), MONTH(s.OrderDate), 1) AS Order_Month,
    SUM(s.OrderQuantity * p.ProductPrice)                    AS Total_Revenue,
    SUM(s.OrderQuantity * (p.ProductPrice - p.ProductCost))  AS Total_Profit,
    COUNT(DISTINCT s.OrderNumber)                            AS Total_Orders
FROM [Sales Data] s
JOIN [Product Lookup] p ON p.ProductKey = s.ProductKey
GROUP BY DATEFROMPARTS(YEAR(s.OrderDate), MONTH(s.OrderDate), 1)
ORDER BY Order_Month;
GO

-- Revenue by category
SELECT
    c.CategoryName,
    SUM(s.OrderQuantity * p.ProductPrice) AS Total_Revenue
FROM [Sales Data] s
JOIN [Product Lookup] p              ON p.ProductKey = s.ProductKey
JOIN [Product Subcategories Lookup] sc ON sc.ProductSubcategoryKey = p.ProductSubcategoryKey
JOIN [Categories Lookup] c            ON c.ProductCategoryKey = sc.ProductCategoryKey
GROUP BY c.CategoryName
ORDER BY Total_Revenue DESC;
GO

-- Current month vs. previous month revenue and returns
WITH Monthly AS (
    SELECT
        DATEFROMPARTS(YEAR(s.OrderDate), MONTH(s.OrderDate), 1) AS Order_Month,
        SUM(s.OrderQuantity * p.ProductPrice)                    AS Total_Revenue
    FROM [Sales Data] s
    JOIN [Product Lookup] p ON p.ProductKey = s.ProductKey
    GROUP BY DATEFROMPARTS(YEAR(s.OrderDate), MONTH(s.OrderDate), 1)
),
Monthly_Returns AS (
    SELECT
        DATEFROMPARTS(YEAR(ReturnDate), MONTH(ReturnDate), 1) AS Return_Month,
        SUM(ReturnQuantity)                                    AS Total_Returns,
        COUNT(*)                                               AS Return_Orders
    FROM [Returns Data]
    GROUP BY DATEFROMPARTS(YEAR(ReturnDate), MONTH(ReturnDate), 1)
)
SELECT
    m.Order_Month,
    m.Total_Revenue,
    LAG(m.Total_Revenue) OVER (ORDER BY m.Order_Month)  AS Previous_Month_Revenue,
    r.Total_Returns,
    LAG(r.Total_Returns) OVER (ORDER BY m.Order_Month)  AS Previous_Month_Returns,
    r.Return_Orders,
    LAG(r.Return_Orders) OVER (ORDER BY m.Order_Month)  AS Previous_Month_Return_Orders
FROM Monthly m
LEFT JOIN Monthly_Returns r ON r.Return_Month = m.Order_Month
ORDER BY m.Order_Month;
GO


-- ============================================================
-- PRODUCT DETAIL
-- ============================================================

-- Top products by revenue and profit
SELECT TOP 20
    p.ProductName,
    p.ModelName,
    SUM(s.OrderQuantity)                                     AS Units_Sold,
    SUM(s.OrderQuantity * p.ProductPrice)                     AS Total_Revenue,
    SUM(s.OrderQuantity * (p.ProductPrice - p.ProductCost))   AS Total_Profit
FROM [Sales Data] s
JOIN [Product Lookup] p ON p.ProductKey = s.ProductKey
GROUP BY p.ProductName, p.ModelName
ORDER BY Total_Revenue DESC;
GO

-- Revenue by subcategory
SELECT
    sc.SubcategoryName,
    SUM(s.OrderQuantity * p.ProductPrice) AS Total_Revenue
FROM [Sales Data] s
JOIN [Product Lookup] p                ON p.ProductKey = s.ProductKey
JOIN [Product Subcategories Lookup] sc ON sc.ProductSubcategoryKey = p.ProductSubcategoryKey
GROUP BY sc.SubcategoryName
ORDER BY Total_Revenue DESC;
GO

-- Return rate by product (units returned / units sold)
SELECT
    p.ProductName,
    SUM(s.OrderQuantity)                          AS Units_Sold,
    ISNULL(ret.Units_Returned, 0)                 AS Units_Returned,
    ISNULL(ret.Units_Returned, 0) * 100.0
        / NULLIF(SUM(s.OrderQuantity), 0)          AS Return_Rate_Pct
FROM [Sales Data] s
JOIN [Product Lookup] p ON p.ProductKey = s.ProductKey
LEFT JOIN (
    SELECT ProductKey, SUM(ReturnQuantity) AS Units_Returned
    FROM [Returns Data]
    GROUP BY ProductKey
) ret ON ret.ProductKey = p.ProductKey
GROUP BY p.ProductName, ret.Units_Returned
ORDER BY Return_Rate_Pct DESC;
GO

-- Average discount vs. list price, by product style
SELECT
    p.ProductStyle,
    AVG(p.ProductPrice)     AS Avg_List_Price,
    AVG(p.[Discount Price]) AS Avg_Discount_Price,
    AVG(p.ProductPrice - p.[Discount Price]) AS Avg_Discount_Amount
FROM [Product Lookup] p
GROUP BY p.ProductStyle
ORDER BY Avg_Discount_Amount DESC;
GO


-- ============================================================
-- CUSTOMER DETAIL
-- ============================================================

-- Revenue by customer gender
SELECT
    c.Gender,
    COUNT(DISTINCT s.CustomerKey)          AS Customers,
    SUM(s.OrderQuantity * p.ProductPrice)  AS Total_Revenue
FROM [Sales Data] s
JOIN [Customer Lookup] c ON c.CustomerKey = s.CustomerKey
JOIN [Product Lookup] p  ON p.ProductKey = s.ProductKey
GROUP BY c.Gender
ORDER BY Total_Revenue DESC;
GO

-- Revenue by marital status and home ownership
SELECT
    c.MaritalStatus,
    c.HomeOwner,
    COUNT(DISTINCT s.CustomerKey)          AS Customers,
    SUM(s.OrderQuantity * p.ProductPrice)  AS Total_Revenue
FROM [Sales Data] s
JOIN [Customer Lookup] c ON c.CustomerKey = s.CustomerKey
JOIN [Product Lookup] p  ON p.ProductKey = s.ProductKey
GROUP BY c.MaritalStatus, c.HomeOwner
ORDER BY Total_Revenue DESC;
GO

-- Revenue by occupation and education level
SELECT
    c.Occupation,
    c.EducationLevel,
    COUNT(DISTINCT s.CustomerKey)          AS Customers,
    SUM(s.OrderQuantity * p.ProductPrice)  AS Total_Revenue
FROM [Sales Data] s
JOIN [Customer Lookup] c ON c.CustomerKey = s.CustomerKey
JOIN [Product Lookup] p  ON p.ProductKey = s.ProductKey
GROUP BY c.Occupation, c.EducationLevel
ORDER BY Total_Revenue DESC;
GO

-- Revenue by annual income band (banding done in SQL since the real
-- AnnualIncome column is numeric — Power BI's "Income level" is a
-- calculated column bucketing this the same way, exact cutoffs unknown)
SELECT
    CASE
        WHEN c.AnnualIncome < 25000  THEN 'Under $25K'
        WHEN c.AnnualIncome < 50000  THEN '$25K - $50K'
        WHEN c.AnnualIncome < 75000  THEN '$50K - $75K'
        WHEN c.AnnualIncome < 100000 THEN '$75K - $100K'
        ELSE '$100K+'
    END AS Income_Band,
    COUNT(DISTINCT s.CustomerKey)          AS Customers,
    SUM(s.OrderQuantity * p.ProductPrice)  AS Total_Revenue
FROM [Sales Data] s
JOIN [Customer Lookup] c ON c.CustomerKey = s.CustomerKey
JOIN [Product Lookup] p  ON p.ProductKey = s.ProductKey
GROUP BY
    CASE
        WHEN c.AnnualIncome < 25000  THEN 'Under $25K'
        WHEN c.AnnualIncome < 50000  THEN '$25K - $50K'
        WHEN c.AnnualIncome < 75000  THEN '$50K - $75K'
        WHEN c.AnnualIncome < 100000 THEN '$75K - $100K'
        ELSE '$100K+'
    END
ORDER BY Total_Revenue DESC;
GO

-- Top 20 customers by revenue
SELECT TOP 20
    c.[Full Name],
    COUNT(DISTINCT s.OrderNumber)          AS Orders,
    SUM(s.OrderQuantity * p.ProductPrice)  AS Total_Revenue
FROM [Sales Data] s
JOIN [Customer Lookup] c ON c.CustomerKey = s.CustomerKey
JOIN [Product Lookup] p  ON p.ProductKey = s.ProductKey
GROUP BY c.[Full Name]
ORDER BY Total_Revenue DESC;
GO


-- ============================================================
-- MAP
-- ============================================================

-- Revenue and orders by country / continent
SELECT
    t.Continent,
    t.Country,
    COUNT(DISTINCT s.OrderNumber)          AS Total_Orders,
    SUM(s.OrderQuantity * p.ProductPrice)  AS Total_Revenue
FROM [Sales Data] s
JOIN [Territory Lookup] t ON t.SalesTerritoryKey = s.TerritoryKey
JOIN [Product Lookup] p   ON p.ProductKey = s.ProductKey
GROUP BY t.Continent, t.Country
ORDER BY Total_Revenue DESC;
GO

-- Returns by territory
SELECT
    t.Continent,
    t.Country,
    SUM(r.ReturnQuantity) AS Total_Units_Returned
FROM [Returns Data] r
JOIN [Territory Lookup] t ON t.SalesTerritoryKey = r.TerritoryKey
GROUP BY t.Continent, t.Country
ORDER BY Total_Units_Returned DESC;
GO
