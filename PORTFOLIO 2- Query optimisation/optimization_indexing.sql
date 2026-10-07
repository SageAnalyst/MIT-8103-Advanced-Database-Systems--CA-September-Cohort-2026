-- Portfolio 2: Query Processing and Optimisation
-- File: optimization_indexing.sql
-- Database: Product_mod
-- Description: DDL statements creating performance-tuning indexes (covering,
--             composite, and filtered access paths) and rewritten SQL queries.

USE Product_mod;


-- 1. INDEX DEFINITIONS FOR SYSTEM PERFORMANCE ENHANCEMENT


-- Index 1: Covering composite index on 'Outreach'
-- Optimises JOIN and GROUP BY queries by covering both the grouping attribute
-- and the foreign key link without needing base-table row lookups.
DROP INDEX IF EXISTS idx_outreach_channel_coll ON Outreach;
CREATE INDEX idx_outreach_channel_coll 
ON Outreach (Outreach, collection_id);

-- Index 2: Covering composite index on 'sales'
-- Satisfies aggregations on (collection_id, Quantity_sold, Price_each) directly
-- from the index B+ Tree leaf pages.
DROP INDEX IF EXISTS idx_sales_covering_analytics ON sales;
CREATE INDEX idx_sales_covering_analytics 
ON sales (collection_id, Quantity_sold, Price_each, Order_date);

-- Index 3: Temporal date index on 'sales'
-- Eliminates full table scans during chronological and multi-year trend queries
-- (e.g., pre-lockdown, lockdown, and post-lockdown window comparisons).
DROP INDEX IF EXISTS idx_sales_order_date ON sales;
CREATE INDEX idx_sales_order_date 
ON sales (Order_date);

-- Index 4: Composite index on 'Products_dets'
-- Optimises catalog searches and size/color aggregations joined with sales.
DROP INDEX IF EXISTS idx_products_size_color ON Products_dets;
CREATE INDEX idx_products_size_color 
ON Products_dets (Product_size, Product_color, collection_id);

-- Index 5: Regional index on 'location'
-- Optimises delivery fee lookups and shipping cost aggregations grouped by State.
DROP INDEX IF EXISTS idx_location_state_fee ON location;
CREATE INDEX idx_location_state_fee 
ON location (State, Delivery_fee, collection_id);

-- Update statistics for the Cost-Based Optimizer (CBO)
ANALYZE TABLE Products_dets;
ANALYZE TABLE sales;
ANALYZE TABLE Outreach;
ANALYZE TABLE location;



-- 2. QUERY RESTRUCTURING & REWRITING



-- Query Rewrite 1: Consolidated Multi-Channel Conversion Analysis
-- Prior implementation executed four separate queries with hardcoded filters
-- for 'Whatsapp', 'Facebook', 'Instagram', and 'Website'.
-- Restructured version uses a unified GROUP BY with Conditional Aggregation,
-- executing in a single table scan pass over the covering index.


--  execution plan:
EXPLAIN ANALYZE
SELECT 
    O.Outreach,
    COUNT(DISTINCT O.collection_id) AS Unique_Products_Promoted,
    COUNT(S.collection_id) AS Total_Sales_Transactions,
    SUM(S.Quantity_sold) AS Total_Units_Sold,
    SUM(S.Quantity_sold * S.Price_each) AS Total_Revenue_Generated,
    ROUND(SUM(S.Quantity_sold) / COUNT(O.collection_id), 2) AS Conversion_Rate
FROM Outreach O
JOIN sales S 
    ON S.collection_id = O.collection_id
GROUP BY O.Outreach
ORDER BY Total_Units_Sold DESC;



-- Query Rewrite 2: Single-Pass Longitudinal Lockdown Trend Evaluation
-- Prior implementation created multiple temporary tables and repeated full scans
-- on `sales` for < 2020, = 2020, and > 2020.
-- Restructured version uses a Common Table Expression (CTE) and CASE expressions
-- to evaluate all three periods in a single pass over the table.


EXPLAIN ANALYZE
WITH PeriodClassifiedSales AS (
    SELECT 
        collection_id,
        Quantity_sold,
        Price_each,
        (Quantity_sold * Price_each) AS Line_Revenue,
        YEAR(Order_date) AS Order_Year,
        CASE 
            WHEN Order_date < '2020-01-01' THEN 'PRE_LOCKDOWN (Before 2020)'
            WHEN Order_date BETWEEN '2020-01-01' AND '2020-12-31' THEN 'DURING_LOCKDOWN (2020)'
            ELSE 'POST_LOCKDOWN (After 2020)'
        END AS Pandemic_Period
    FROM sales
)
SELECT 
    Pandemic_Period,
    COUNT(DISTINCT Order_Year) AS Number_Of_Years,
    SUM(Quantity_sold) AS Total_Units_Sold,
    SUM(Line_Revenue) AS Total_Gross_Revenue,
    ROUND(AVG(Quantity_sold), 2) AS Avg_Units_Per_Transaction,
    ROUND(SUM(Line_Revenue) / NULLIF(COUNT(DISTINCT Order_Year), 0), 2) AS Avg_Annual_Revenue
FROM PeriodClassifiedSales
GROUP BY Pandemic_Period
ORDER BY FIELD(Pandemic_Period, 'PRE_LOCKDOWN (Before 2020)', 'DURING_LOCKDOWN (2020)', 'POST_LOCKDOWN (After 2020)');



-- Query Rewrite 3: Subquery Elimination for Product Catalog Extremes
-- Replaces multiple scalar SELECTs for highest/lowest delivery fees with a single
-- window function CTE, scanning the indexed location table only once.


EXPLAIN ANALYZE
WITH DeliveryRankings AS (
    SELECT 
        collection_id,
        order_address,
        State,
        Delivery_fee,
        DENSE_RANK() OVER (ORDER BY Delivery_fee DESC) AS Rank_High,
        DENSE_RANK() OVER (ORDER BY Delivery_fee ASC) AS Rank_Low
    FROM location
)
SELECT 
    'HIGHEST_DELIVERY_FEE' AS Metric_Type,
    collection_id,
    order_address,
    State,
    Delivery_fee
FROM DeliveryRankings
WHERE Rank_High = 1
UNION ALL
SELECT 
    'LOWEST_DELIVERY_FEE' AS Metric_Type,
    collection_id,
    order_address,
    State,
    Delivery_fee
FROM DeliveryRankings
WHERE Rank_Low = 1;
