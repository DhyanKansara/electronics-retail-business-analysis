SHOW TABLES;
#-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x#    
DESCRIBE stores;
#-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x#    
SELECT
    StoreKey,
    COUNT(*) AS sales_rows,
    COUNT(DISTINCT `Order Number`) AS total_orders
FROM sales
GROUP BY StoreKey
ORDER BY StoreKey;
#-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x#    
SELECT *
FROM stores
WHERE StoreKey = 0;

SELECT
    CASE
        WHEN StoreKey = 0 THEN 'StoreKey 0'
        ELSE 'Physical Store'
    END AS sales_channel,

    COUNT(*) AS sales_rows,

    COUNT(DISTINCT `Order Number`) AS total_orders,

    SUM(
        CASE
            WHEN `Delivery Date` IS NOT NULL
                 AND TRIM(`Delivery Date`) <> ''
            THEN 1
            ELSE 0
        END
    ) AS rows_with_delivery_date,

    SUM(
        CASE
            WHEN `Delivery Date` IS NULL
                 OR TRIM(`Delivery Date`) = ''
            THEN 1
            ELSE 0
        END
    ) AS rows_without_delivery_date

FROM sales

GROUP BY
    CASE
        WHEN StoreKey = 0 THEN 'StoreKey 0'
        ELSE 'Physical Store'
    END;