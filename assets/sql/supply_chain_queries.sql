-- ============================================================
-- Supply Chain Analytics — SQL
-- SQL Server (T-SQL). Two parts:
--   PART 1: Data model — star schema views built on the raw
--           staging table (stg_supply_chain), loaded into Power BI.
--   PART 2: Analytical queries — mirror the DAX measures used in
--           the Power BI report, written against the views below.
-- ============================================================


-- ============================================================
-- PART 1: Data model
-- ============================================================

CREATE DATABASE SupplyChainAnalytics;
GO

USE SupplyChainAnalytics;
GO

SELECT TOP 10 *
FROM stg_supply_chain;
GO

-- 1. Customer dimension
CREATE VIEW vw_DimCustomer AS
SELECT DISTINCT
    Customer_Id,
    Customer_Fname,
    Customer_Lname,
    CONCAT(Customer_Fname, ' ', Customer_Lname) AS Customer_Name,
    Customer_Segment,
    Customer_City,
    Customer_State,
    Customer_Country,
    Customer_Zipcode
FROM stg_supply_chain;
GO

-- 2. Product dimension
CREATE VIEW vw_DimProduct AS
SELECT DISTINCT
    Product_Card_Id,
    Product_Name,
    Product_Category_Id,
    Category_Id,
    Category_Name,
    Department_Id,
    Department_Name,
    Product_Price,
    Product_Status
FROM stg_supply_chain;
GO

-- 3. Location dimension
CREATE VIEW vw_DimLocation AS
SELECT
    Order_Zipcode,
    MAX(Market) AS Market,
    MAX(Order_Country) AS Order_Country,
    MAX(Order_Region) AS Order_Region,
    MAX(Order_State) AS Order_State,
    MAX(Order_City) AS Order_City,
    AVG(Latitude) AS Latitude,
    AVG(Longitude) AS Longitude
FROM stg_supply_chain
WHERE Order_Zipcode IS NOT NULL
GROUP BY Order_Zipcode;
GO

-- 4. Shipping dimension
CREATE VIEW vw_DimShipping AS
SELECT DISTINCT
    Shipping_Mode,
    Delivery_Status,
    Late_delivery_risk
FROM stg_supply_chain;
GO

-- 5. Fact table (order line item grain)
CREATE VIEW vw_FactOrders AS
SELECT
    Order_Id,
    Order_Zipcode,
    Order_Item_Id,
    Order_Customer_Id,
    Customer_Id,
    Product_Card_Id,
    order_date_DateOrders,
    shipping_date_DateOrders,
    Type AS Payment_Type,
    Days_for_shipping_real,
    Days_for_shipment_scheduled,
    Delivery_Status,
    Late_delivery_risk,
    Shipping_Mode,
    Order_Status,
    Market,
    Order_Region,
    Order_Country,
    Order_State,
    Order_City,
    Order_Item_Quantity,
    Sales,
    Order_Item_Total,
    Order_Item_Discount,
    Order_Item_Discount_Rate,
    Order_Item_Product_Price,
    Order_Item_Profit_Ratio,
    Order_Profit_Per_Order,
    Benefit_per_order
FROM stg_supply_chain;
GO

SELECT TOP 10 * FROM vw_DimCustomer;
SELECT TOP 10 * FROM vw_DimProduct;
SELECT TOP 10 * FROM vw_DimLocation;
SELECT TOP 10 * FROM vw_DimShipping;
SELECT TOP 10 * FROM vw_FactOrders;
GO


-- ============================================================
-- PART 2: Analytical queries
-- Mirrors the DAX measures behind each report page.
-- ============================================================

-- Headline KPIs (Executive Overview page)
SELECT
    SUM(Sales)                                             AS Total_Sales,
    SUM(Order_Profit_Per_Order)                            AS Total_Profit,
    COUNT(DISTINCT Order_Id)                                AS Total_Orders,
    COUNT(DISTINCT Customer_Id)                             AS Total_Customers,
    SUM(Sales) / NULLIF(COUNT(DISTINCT Order_Id), 0)        AS Avg_Order_Value,
    SUM(Order_Profit_Per_Order) / NULLIF(SUM(Sales), 0)     AS Profit_Margin_Pct
FROM vw_FactOrders;
GO

-- Monthly sales & profit trend
SELECT
    DATEFROMPARTS(YEAR(order_date_DateOrders), MONTH(order_date_DateOrders), 1) AS Order_Month,
    SUM(Sales)                       AS Total_Sales,
    SUM(Order_Profit_Per_Order)      AS Total_Profit,
    COUNT(DISTINCT Order_Id)         AS Total_Orders
FROM vw_FactOrders
GROUP BY DATEFROMPARTS(YEAR(order_date_DateOrders), MONTH(order_date_DateOrders), 1)
ORDER BY Order_Month;
GO

-- Sales by market
SELECT Market, SUM(Sales) AS Total_Sales
FROM vw_FactOrders
GROUP BY Market
ORDER BY Total_Sales DESC;
GO

-- Sales by department
SELECT p.Department_Name, SUM(f.Sales) AS Total_Sales
FROM vw_FactOrders f
JOIN vw_DimProduct p ON p.Product_Card_Id = f.Product_Card_Id
GROUP BY p.Department_Name
ORDER BY Total_Sales DESC;
GO

-- Late delivery rate + actual vs. scheduled shipping days, by shipping mode
-- (Shipping & Fulfillment page)
SELECT
    Shipping_Mode,
    AVG(CASE WHEN Late_delivery_risk = 1 THEN 1.0 ELSE 0 END) * 100 AS Late_Delivery_Rate_Pct,
    AVG(CAST(Days_for_shipping_real AS FLOAT))                       AS Avg_Actual_Days,
    AVG(CAST(Days_for_shipment_scheduled AS FLOAT))                  AS Avg_Scheduled_Days
FROM vw_FactOrders
GROUP BY Shipping_Mode
ORDER BY Late_Delivery_Rate_Pct DESC;
GO

-- Delivery status breakdown
SELECT
    Delivery_Status,
    COUNT(DISTINCT Order_Id) AS Order_Count,
    COUNT(DISTINCT Order_Id) * 100.0 / SUM(COUNT(DISTINCT Order_Id)) OVER () AS Pct_Of_Orders
FROM vw_FactOrders
GROUP BY Delivery_Status
ORDER BY Order_Count DESC;
GO

-- Order status breakdown
SELECT Order_Status, COUNT(DISTINCT Order_Id) AS Order_Count
FROM vw_FactOrders
GROUP BY Order_Status
ORDER BY Order_Count DESC;
GO

-- Top 10 products by sales / profit (Products & Customers page)
SELECT TOP 10
    p.Product_Name,
    SUM(f.Sales)                  AS Total_Sales,
    SUM(f.Order_Profit_Per_Order) AS Total_Profit
FROM vw_FactOrders f
JOIN vw_DimProduct p ON p.Product_Card_Id = f.Product_Card_Id
GROUP BY p.Product_Name
ORDER BY Total_Sales DESC;
GO

-- Top categories by sales
SELECT TOP 10
    p.Category_Name,
    SUM(f.Sales) AS Total_Sales
FROM vw_FactOrders f
JOIN vw_DimProduct p ON p.Product_Card_Id = f.Product_Card_Id
GROUP BY p.Category_Name
ORDER BY Total_Sales DESC;
GO

-- Customer segment sales share
SELECT
    c.Customer_Segment,
    SUM(f.Sales)                    AS Total_Sales,
    COUNT(DISTINCT f.Customer_Id)   AS Customers
FROM vw_FactOrders f
JOIN vw_DimCustomer c ON c.Customer_Id = f.Customer_Id
GROUP BY c.Customer_Segment
ORDER BY Total_Sales DESC;
GO

-- Repeat customer rate: share of customers with more than one order
WITH Orders_Per_Customer AS (
    SELECT Customer_Id, COUNT(DISTINCT Order_Id) AS Order_Count
    FROM vw_FactOrders
    GROUP BY Customer_Id
)
SELECT
    SUM(CASE WHEN Order_Count > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS Repeat_Customer_Rate_Pct
FROM Orders_Per_Customer;
GO

-- Payment type breakdown
SELECT
    Payment_Type,
    COUNT(DISTINCT Order_Id) AS Order_Count,
    SUM(Sales)                AS Total_Sales
FROM vw_FactOrders
GROUP BY Payment_Type
ORDER BY Total_Sales DESC;
GO

-- Top countries by sales
SELECT
    Order_Country,
    SUM(Sales) AS Total_Sales
FROM vw_FactOrders
GROUP BY Order_Country
ORDER BY Total_Sales DESC;
GO
