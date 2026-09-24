-- ELECTRONICS RETAIL BUSINESS ANALYSIS
-- Clean SQL portfolio file
-- Database: electronics_retail
-- MySQL 8.x
--
-- This file consolidates the final, meaningful analyses from the
-- project's SQL work. Exploratory/debugging and duplicate queries
-- have been removed.

USE electronics_retail;


-- ============================================================
-- 1. DATASET OVERVIEW
-- ============================================================

SELECT
    COUNT(*) AS total_line_items,
    COUNT(DISTINCT `Order Number`) AS total_orders,
    SUM(Quantity) AS total_quantity
FROM sales;


-- ============================================================
-- 2. SALES CHANNEL ANALYSIS
-- ============================================================

-- Orders and quantity by channel
SELECT
    CASE WHEN StoreKey = 0 THEN 'Online' ELSE 'In-Store' END AS sales_channel,
    COUNT(DISTINCT `Order Number`) AS total_orders,
    SUM(Quantity) AS total_quantity
FROM sales
GROUP BY CASE WHEN StoreKey = 0 THEN 'Online' ELSE 'In-Store' END;


-- Revenue and Average Order Value by channel
SELECT
    CASE WHEN s.StoreKey = 0 THEN 'Online' ELSE 'In-Store' END AS sales_channel,
    COUNT(DISTINCT s.`Order Number`) AS total_orders,
    ROUND(SUM(
        s.Quantity * CAST(REPLACE(p.`Unit Price USD`, '$', '') AS DECIMAL(10,2))
    ), 2) AS total_revenue,
    ROUND(
        SUM(
            s.Quantity * CAST(REPLACE(p.`Unit Price USD`, '$', '') AS DECIMAL(10,2))
        ) / COUNT(DISTINCT s.`Order Number`),
        2
    ) AS aov
FROM sales s
JOIN products p ON s.ProductKey = p.ProductKey
GROUP BY CASE WHEN s.StoreKey = 0 THEN 'Online' ELSE 'In-Store' END;


-- ============================================================
-- 3. CATEGORY PERFORMANCE
-- ============================================================

SELECT
    p.Category,
    SUM(s.Quantity) AS total_quantity,
    ROUND(SUM(
        s.Quantity * CAST(REPLACE(p.`Unit Price USD`, '$', '') AS DECIMAL(10,2))
    ), 2) AS total_revenue,
    ROUND(SUM(
        s.Quantity * (
            CAST(REPLACE(p.`Unit Price USD`, '$', '') AS DECIMAL(10,2))
            - CAST(REPLACE(p.`Unit Cost USD`, '$', '') AS DECIMAL(10,2))
        )
    ), 2) AS total_profit
FROM sales s
JOIN products p ON s.ProductKey = p.ProductKey
GROUP BY p.Category
ORDER BY total_revenue DESC;


-- ============================================================
-- 4. SALES TRENDS
-- ============================================================

-- Revenue and orders by year
SELECT
    YEAR(STR_TO_DATE(s.`Order Date`, '%m/%d/%Y')) AS order_year,
    COUNT(DISTINCT s.`Order Number`) AS total_orders,
    ROUND(SUM(
        s.Quantity * CAST(REPLACE(p.`Unit Price USD`, '$', '') AS DECIMAL(10,2))
    ), 2) AS total_revenue
FROM sales s
JOIN products p ON s.ProductKey = p.ProductKey
GROUP BY YEAR(STR_TO_DATE(s.`Order Date`, '%m/%d/%Y'))
ORDER BY order_year;


-- Year-over-year change
WITH yearly_sales AS (
    SELECT
        YEAR(STR_TO_DATE(s.`Order Date`, '%m/%d/%Y')) AS order_year,
        COUNT(DISTINCT s.`Order Number`) AS total_orders,
        SUM(
            s.Quantity * CAST(REPLACE(p.`Unit Price USD`, '$', '') AS DECIMAL(10,2))
        ) AS total_revenue
    FROM sales s
    JOIN products p ON s.ProductKey = p.ProductKey
    GROUP BY YEAR(STR_TO_DATE(s.`Order Date`, '%m/%d/%Y'))
)
SELECT
    order_year,
    total_orders,
    ROUND(total_revenue, 2) AS total_revenue,
    LAG(total_orders) OVER (ORDER BY order_year) AS previous_year_orders,
    ROUND(
        (total_orders - LAG(total_orders) OVER (ORDER BY order_year))
        / NULLIF(LAG(total_orders) OVER (ORDER BY order_year), 0) * 100,
        2
    ) AS orders_yoy_change_pct,
    ROUND(LAG(total_revenue) OVER (ORDER BY order_year), 2) AS previous_year_revenue,
    ROUND(
        (total_revenue - LAG(total_revenue) OVER (ORDER BY order_year))
        / NULLIF(LAG(total_revenue) OVER (ORDER BY order_year), 0) * 100,
        2
    ) AS revenue_yoy_change_pct
FROM yearly_sales
ORDER BY order_year;


-- Revenue and orders by day of week
SELECT
    DAYNAME(STR_TO_DATE(s.`Order Date`, '%m/%d/%Y')) AS day_name,
    COUNT(DISTINCT s.`Order Number`) AS total_orders,
    ROUND(SUM(
        s.Quantity * CAST(REPLACE(p.`Unit Price USD`, '$', '') AS DECIMAL(10,2))
    ), 2) AS total_revenue
FROM sales s
JOIN products p ON s.ProductKey = p.ProductKey
WHERE YEAR(STR_TO_DATE(s.`Order Date`, '%m/%d/%Y')) BETWEEN 2016 AND 2020
GROUP BY
    DAYOFWEEK(STR_TO_DATE(s.`Order Date`, '%m/%d/%Y')),
    DAYNAME(STR_TO_DATE(s.`Order Date`, '%m/%d/%Y'))
ORDER BY DAYOFWEEK(STR_TO_DATE(s.`Order Date`, '%m/%d/%Y'));


-- ============================================================
-- 5. SEASONALITY / HIGH-DEMAND PERIODS
-- ============================================================

-- The project's analysis identified weeks 1, 7, 8, 9, 51 and 52
-- as the high-demand weeks used for comparison.
WITH weekly_sales AS (
    SELECT
        YEARWEEK(STR_TO_DATE(s.`Order Date`, '%m/%d/%Y'), 3) AS year_week,
        WEEK(STR_TO_DATE(s.`Order Date`, '%m/%d/%Y'), 3) AS week_number,
        COUNT(DISTINCT s.`Order Number`) AS total_orders,
        SUM(
            s.Quantity * CAST(REPLACE(p.`Unit Price USD`, '$', '') AS DECIMAL(10,2))
        ) AS total_revenue
    FROM sales s
    JOIN products p ON s.ProductKey = p.ProductKey
    WHERE YEAR(STR_TO_DATE(s.`Order Date`, '%m/%d/%Y')) BETWEEN 2016 AND 2020
    GROUP BY
        YEARWEEK(STR_TO_DATE(s.`Order Date`, '%m/%d/%Y'), 3),
        WEEK(STR_TO_DATE(s.`Order Date`, '%m/%d/%Y'), 3)
)
SELECT
    CASE
        WHEN week_number IN (1, 7, 8, 9, 51, 52)
            THEN 'High-demand period'
        ELSE 'Other weeks'
    END AS period_type,
    SUM(total_orders) AS total_orders,
    ROUND(SUM(total_revenue), 2) AS total_revenue,
    ROUND(SUM(total_revenue) / NULLIF(SUM(total_orders), 0), 2) AS average_order_value
FROM weekly_sales
GROUP BY
    CASE
        WHEN week_number IN (1, 7, 8, 9, 51, 52)
            THEN 'High-demand period'
        ELSE 'Other weeks'
    END;


-- Category performance during high-demand vs other weeks
SELECT
    CASE
        WHEN WEEK(STR_TO_DATE(s.`Order Date`, '%m/%d/%Y'), 3)
             IN (1, 7, 8, 9, 51, 52)
            THEN 'High-demand period'
        ELSE 'Other weeks'
    END AS period_type,
    p.Category,
    COUNT(DISTINCT s.`Order Number`) AS total_orders,
    ROUND(SUM(
        s.Quantity * CAST(REPLACE(p.`Unit Price USD`, '$', '') AS DECIMAL(10,2))
    ), 2) AS total_revenue,
    ROUND(
        SUM(
            s.Quantity * CAST(REPLACE(p.`Unit Price USD`, '$', '') AS DECIMAL(10,2))
        ) / COUNT(DISTINCT s.`Order Number`),
        2
    ) AS revenue_per_order
FROM sales s
JOIN products p ON s.ProductKey = p.ProductKey
WHERE YEAR(STR_TO_DATE(s.`Order Date`, '%m/%d/%Y')) BETWEEN 2016 AND 2020
GROUP BY period_type, p.Category
ORDER BY period_type, total_revenue DESC;


-- Category revenue uplift during high-demand weeks
WITH weekly_category_sales AS (
    SELECT
        YEARWEEK(STR_TO_DATE(s.`Order Date`, '%m/%d/%Y'), 3) AS year_week,
        WEEK(STR_TO_DATE(s.`Order Date`, '%m/%d/%Y'), 3) AS week_number,
        p.Category,
        SUM(
            s.Quantity * CAST(REPLACE(p.`Unit Price USD`, '$', '') AS DECIMAL(10,2))
        ) AS weekly_revenue
    FROM sales s
    JOIN products p ON s.ProductKey = p.ProductKey
    WHERE YEAR(STR_TO_DATE(s.`Order Date`, '%m/%d/%Y')) BETWEEN 2016 AND 2020
    GROUP BY
        YEARWEEK(STR_TO_DATE(s.`Order Date`, '%m/%d/%Y'), 3),
        WEEK(STR_TO_DATE(s.`Order Date`, '%m/%d/%Y'), 3),
        p.Category
),
category_comparison AS (
    SELECT
        Category,
        AVG(CASE
            WHEN week_number IN (1, 7, 8, 9, 51, 52)
            THEN weekly_revenue
        END) AS avg_high_demand_week_revenue,
        AVG(CASE
            WHEN week_number NOT IN (1, 7, 8, 9, 51, 52)
            THEN weekly_revenue
        END) AS avg_other_week_revenue
    FROM weekly_category_sales
    GROUP BY Category
)
SELECT
    Category,
    ROUND(avg_high_demand_week_revenue, 2) AS avg_high_demand_week_revenue,
    ROUND(avg_other_week_revenue, 2) AS avg_other_week_revenue,
    ROUND(
        (avg_high_demand_week_revenue - avg_other_week_revenue)
        / NULLIF(avg_other_week_revenue, 0) * 100,
        2
    ) AS high_demand_uplift_pct
FROM category_comparison
ORDER BY high_demand_uplift_pct DESC;


-- ============================================================
-- 6. CUSTOMER & GEOGRAPHIC ANALYSIS
-- ============================================================

-- Country-level customer, order, revenue and profit performance
SELECT
    c.Country,
    COUNT(DISTINCT c.CustomerKey) AS total_customers,
    COUNT(DISTINCT s.`Order Number`) AS total_orders,
    ROUND(SUM(
        s.Quantity * CAST(REPLACE(p.`Unit Price USD`, '$', '') AS DECIMAL(10,2))
    ), 2) AS total_revenue,
    ROUND(SUM(
        s.Quantity * (
            CAST(REPLACE(p.`Unit Price USD`, '$', '') AS DECIMAL(10,2))
            - CAST(REPLACE(p.`Unit Cost USD`, '$', '') AS DECIMAL(10,2))
        )
    ), 2) AS total_profit
FROM sales s
JOIN customers c ON s.CustomerKey = c.CustomerKey
JOIN products p ON s.ProductKey = p.ProductKey
GROUP BY c.Country
ORDER BY total_revenue DESC;


-- Revenue, profit and margin by country and category
SELECT
    c.Country,
    p.Category,
    COUNT(DISTINCT s.`Order Number`) AS total_orders,
    ROUND(SUM(
        s.Quantity * CAST(REPLACE(p.`Unit Price USD`, '$', '') AS DECIMAL(10,2))
    ), 2) AS total_revenue,
    ROUND(SUM(
        s.Quantity * (
            CAST(REPLACE(p.`Unit Price USD`, '$', '') AS DECIMAL(10,2))
            - CAST(REPLACE(p.`Unit Cost USD`, '$', '') AS DECIMAL(10,2))
        )
    ), 2) AS total_profit,
    ROUND(
        SUM(
            s.Quantity * (
                CAST(REPLACE(p.`Unit Price USD`, '$', '') AS DECIMAL(10,2))
                - CAST(REPLACE(p.`Unit Cost USD`, '$', '') AS DECIMAL(10,2))
            )
        )
        / NULLIF(
            SUM(
                s.Quantity * CAST(REPLACE(p.`Unit Price USD`, '$', '') AS DECIMAL(10,2))
            ),
            0
        ) * 100,
        2
    ) AS profit_margin_pct
FROM sales s
JOIN customers c ON s.CustomerKey = c.CustomerKey
JOIN products p ON s.ProductKey = p.ProductKey
GROUP BY c.Country, p.Category
ORDER BY c.Country, total_revenue DESC;


-- ============================================================
-- 7. STORE / MARKET ANALYSIS
-- ============================================================

-- Top physical stores/markets by revenue
SELECT
    st.StoreKey,
    st.Country,
    st.State,
    SUM(s.Quantity) AS total_quantity,
    ROUND(SUM(
        s.Quantity * CAST(REPLACE(p.`Unit Price USD`, '$', '') AS DECIMAL(10,2))
    ), 2) AS total_revenue
FROM sales s
JOIN stores st ON s.StoreKey = st.StoreKey
JOIN products p ON s.ProductKey = p.ProductKey
GROUP BY st.StoreKey, st.Country, st.State
ORDER BY total_revenue DESC
LIMIT 10;


-- Country-level market performance
SELECT
    st.Country,
    SUM(s.Quantity) AS total_quantity,
    ROUND(SUM(
        s.Quantity * CAST(REPLACE(p.`Unit Price USD`, '$', '') AS DECIMAL(10,2))
    ), 2) AS total_revenue
FROM sales s
JOIN stores st ON s.StoreKey = st.StoreKey
JOIN products p ON s.ProductKey = p.ProductKey
GROUP BY st.Country
ORDER BY total_revenue DESC;


-- ============================================================
-- 8. PRODUCT PROFITABILITY
-- ============================================================

-- Revenue, profit and profit margin for every product
WITH product_profitability AS (
    SELECT
        p.`ProductKey`,
        p.`Product Name`,
        p.Category,
        SUM(
            s.Quantity * CAST(REPLACE(p.`Unit Price USD`, '$', '') AS DECIMAL(10,2))
        ) AS total_revenue,
        SUM(
            s.Quantity * (
                CAST(REPLACE(p.`Unit Price USD`, '$', '') AS DECIMAL(10,2))
                - CAST(REPLACE(p.`Unit Cost USD`, '$', '') AS DECIMAL(10,2))
            )
        ) AS total_profit
    FROM sales s
    JOIN products p ON s.ProductKey = p.ProductKey
    GROUP BY p.`ProductKey`, p.`Product Name`, p.Category
)
SELECT
    `ProductKey`,
    `Product Name`,
    Category,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(total_profit, 2) AS total_profit,
    ROUND(
        total_profit / NULLIF(total_revenue, 0) * 100,
        2
    ) AS profit_margin_pct
FROM product_profitability
ORDER BY total_revenue DESC;


-- ============================================================
-- 9. NEW-PRODUCT LAUNCH SUPPORT
-- ============================================================

-- Historical category performance during high-demand periods.
-- This supports the project's launch-category/timing analysis.
WITH weekly_category_sales AS (
    SELECT
        YEARWEEK(STR_TO_DATE(s.`Order Date`, '%m/%d/%Y'), 3) AS year_week,
        WEEK(STR_TO_DATE(s.`Order Date`, '%m/%d/%Y'), 3) AS week_number,
        p.Category,
        SUM(
            s.Quantity * CAST(REPLACE(p.`Unit Price USD`, '$', '') AS DECIMAL(10,2))
        ) AS weekly_revenue
    FROM sales s
    JOIN products p ON s.ProductKey = p.ProductKey
    WHERE YEAR(STR_TO_DATE(s.`Order Date`, '%m/%d/%Y')) BETWEEN 2016 AND 2020
    GROUP BY
        YEARWEEK(STR_TO_DATE(s.`Order Date`, '%m/%d/%Y'), 3),
        WEEK(STR_TO_DATE(s.`Order Date`, '%m/%d/%Y'), 3),
        p.Category
),
category_comparison AS (
    SELECT
        Category,
        AVG(CASE
            WHEN week_number IN (1, 7, 8, 9, 51, 52)
            THEN weekly_revenue
        END) AS avg_high_demand_revenue,
        AVG(CASE
            WHEN week_number NOT IN (1, 7, 8, 9, 51, 52)
            THEN weekly_revenue
        END) AS avg_other_week_revenue
    FROM weekly_category_sales
    GROUP BY Category
)
SELECT
    Category,
    ROUND(avg_high_demand_revenue, 2) AS avg_high_demand_revenue,
    ROUND(avg_other_week_revenue, 2) AS avg_other_week_revenue,
    ROUND(
        (avg_high_demand_revenue - avg_other_week_revenue)
        / NULLIF(avg_other_week_revenue, 0) * 100,
        2
    ) AS revenue_uplift_pct
FROM category_comparison
ORDER BY revenue_uplift_pct DESC;


-- ============================================================
-- 10. DELIVERY-DATE DATA QUALITY
-- ============================================================

-- The supplied project SQL used this check to identify missing
-- delivery/order dates before delivery-time analysis.
SELECT
    COUNT(*) AS total_sales_rows,
    SUM(CASE
        WHEN `Delivery Date` IS NULL OR TRIM(`Delivery Date`) = ''
        THEN 1 ELSE 0
    END) AS missing_delivery_dates,
    SUM(CASE
        WHEN `Order Date` IS NULL OR TRIM(`Order Date`) = ''
        THEN 1 ELSE 0
    END) AS missing_order_dates
FROM sales;


-- ============================================================
-- END OF SQL ANALYSIS
-- ============================================================
