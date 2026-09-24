CREATE DATABASE fedex_db;
USE fedex_db;
SHOW TABLES;
SELECT * FROM `fedex_orders.xlsx` LIMIT 10;
SELECT * FROM `fedex_routes.xlsx` LIMIT 10;
SELECT * FROM `fedex_warehouses.xlsx` LIMIT 10;
SELECT * FROM `fedex_delivery_agents.xlsx` LIMIT 10;
SELECT * FROM `fedex_shipments.xlsx` LIMIT 10;
SELECT COUNT(*) FROM `fedex_orders.xlsx`;
SELECT COUNT(*) FROM `fedex_routes.xlsx`;
SELECT COUNT(*) FROM `fedex_warehouses.xlsx`;
SELECT COUNT(*) FROM `fedex_delivery_agents.xlsx`;
SELECT COUNT(*) FROM `fedex_shipments.xlsx`;
DESCRIBE `fedex_orders.xlsx`;
DESCRIBE `fedex_routes.xlsx`;
DESCRIBE `fedex_warehouses.xlsx`;
DESCRIBE `fedex_delivery_agents.xlsx`;
DESCRIBE `fedex_shipments.xlsx`;

-- TASK 1 – Data Cleaning & Preparation --
 
-- 1.1 Check Duplicate Order_ID --
SELECT Order_ID, 
COUNT(*) AS Total_Records
FROM `fedex_orders.xlsx`
GROUP BY Order_ID
HAVING COUNT(*) > 1;

-- 1.2 Check Duplicate Shipment_ID -- 
SELECT Shipment_ID,
COUNT(*) AS Total_Records
FROM `fedex_shipments.xlsx`
GROUP BY Shipment_ID
HAVING COUNT(*) > 1;

-- 1.3 Check NULL Delay_Hours -- 
SELECT *
FROM `fedex_shipments.xlsx`
WHERE Delay_Hours IS NULL;

-- 1.4 Replace NULL Delay_Hours with Route Average --
UPDATE `fedex_shipments.xlsx` s
JOIN
(
SELECT Route_ID,
AVG(Delay_Hours) AS AvgDelay
FROM `fedex_shipments.xlsx`
WHERE Delay_Hours IS NOT NULL
GROUP BY Route_ID
) r
ON s.Route_ID=r.Route_ID
SET s.Delay_Hours=r.AvgDelay
WHERE s.Delay_Hours IS NULL;

-- 1.5 Verify NULL Values Removed -- 
SELECT *
FROM `fedex_shipments.xlsx`
WHERE Delay_Hours IS NULL;

-- 1.6 Check Invalid Dates --
SELECT Shipment_ID,
Pickup_Date,
Delivery_Date
FROM `fedex_shipments.xlsx`
WHERE STR_TO_DATE(Delivery_Date,'%Y-%m-%d %H:%i:%s')
<
STR_TO_DATE(Pickup_Date,'%Y-%m-%d %H:%i:%s');

-- 1.7 Check Date Format -- 
SELECT
Shipment_ID,
STR_TO_DATE(Pickup_Date,'%Y-%m-%d %H:%i:%s') AS Pickup,
STR_TO_DATE(Delivery_Date,'%Y-%m-%d %H:%i:%s') AS Delivery
FROM `fedex_shipments.xlsx`;

-- 1.8 Orders Without Shipment -- 
SELECT o.Order_ID
FROM `fedex_orders.xlsx` o
LEFT JOIN `fedex_shipments.xlsx` s
ON o.Order_ID=s.Order_ID
WHERE s.Order_ID IS NULL;

-- 1.9 Invalid Route_ID --
SELECT s.Route_ID
FROM `fedex_shipments.xlsx` s
LEFT JOIN `fedex_routes.xlsx` r
ON s.Route_ID=r.Route_ID
WHERE r.Route_ID IS NULL;

-- 1.10 Invalid Warehouse_ID --
SELECT s.Warehouse_ID
FROM `fedex_shipments.xlsx` s
LEFT JOIN `fedex_warehouses.xlsx` w
ON s.Warehouse_ID=w.Warehouse_ID
WHERE w.Warehouse_ID IS NULL;

-- TASK 1 – Delivery Delay Analysis --

-- 2.1  Calculate Delivery Delay (Hours) --
SELECT
    Shipment_ID,
    Order_ID,
    Route_ID,
    TIMESTAMPDIFF(
        HOUR,
        STR_TO_DATE(Pickup_Date,'%Y-%m-%d %H:%i:%s'),
        STR_TO_DATE(Delivery_Date,'%Y-%m-%d %H:%i:%s')
    ) AS Delivery_Delay_Hours
FROM `fedex_shipments.xlsx`;

-- 2.2 Top 10 Delayed Routes --
SELECT
    Route_ID,
    ROUND(AVG(Delay_Hours),2) AS Average_Delay_Hours
FROM `fedex_shipments.xlsx`
GROUP BY Route_ID
ORDER BY Average_Delay_Hours DESC
LIMIT 10;

-- 2.3 Rank Shipments by Delay within each Warehouse  --
SELECT
    Shipment_ID,
    Warehouse_ID,
    Delay_Hours,
    DENSE_RANK() OVER(
        PARTITION BY Warehouse_ID
        ORDER BY Delay_Hours DESC
    ) AS Delay_Rank
FROM `fedex_shipments.xlsx`;

-- 2.4 Average Delay by Delivery Type  --

SELECT
    o.Delivery_Type,
    ROUND(AVG(s.Delay_Hours),2) AS Average_Delay_Hours
FROM `fedex_orders.xlsx` o
JOIN `fedex_shipments.xlsx` s
ON o.Order_ID = s.Order_ID
GROUP BY o.Delivery_Type;

-- TASK 3 – Route Optimization Insights -- 

-- Query 3.1  Average Transit Time for Each Route -- 
SELECT
    Route_ID,
    ROUND(
        AVG(
            TIMESTAMPDIFF(
                HOUR,
                STR_TO_DATE(Pickup_Date,'%Y-%m-%d %H:%i:%s'),
                STR_TO_DATE(Delivery_Date,'%Y-%m-%d %H:%i:%s')
            )
        ),2
    ) AS Avg_Transit_Time_Hours
FROM `fedex_shipments.xlsx`
GROUP BY Route_ID;

-- Query 3.2 – Average Delay per Route -- 
SELECT
    Route_ID,
    ROUND(AVG(Delay_Hours),2) AS Average_Delay
FROM `fedex_shipments.xlsx`
GROUP BY Route_ID
ORDER BY Average_Delay DESC;

-- Query 3.3 – Distance-to-Time Efficiency Ratio --
SELECT
    Route_ID,
    Distance_KM,
    Avg_Transit_Time_Hours,
    ROUND(
        Distance_KM / Avg_Transit_Time_Hours,
        2
    ) AS Efficiency_Ratio
FROM `fedex_routes.xlsx`;

-- Query 3.4 – Worst 3 Routes --
SELECT
    Route_ID,
    Distance_KM,
    Avg_Transit_Time_Hours,
    ROUND(
        Distance_KM / Avg_Transit_Time_Hours,
        2
    ) AS Efficiency_Ratio
FROM `fedex_routes.xlsx`
ORDER BY Efficiency_Ratio ASC
LIMIT 3;

-- Query 3.5 – Routes with More Than 20% Delayed Shipments --
SELECT
    Route_ID,
    ROUND(
        SUM(
            CASE
                WHEN Delay_Hours > Avg_Transit_Time_Hours THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS Delay_Percentage
FROM `fedex_shipments.xlsx`
JOIN `fedex_routes.xlsx`
USING(Route_ID)
GROUP BY Route_ID
HAVING Delay_Percentage > 20;

-- Query 3.6 – Route Recommendation -- 
SELECT
    Route_ID,
    ROUND(AVG(Delay_Hours),2) AS Avg_Delay,
    CASE
        WHEN AVG(Delay_Hours) > 24
            THEN 'High Priority Optimization'
        WHEN AVG(Delay_Hours) BETWEEN 12 AND 24
            THEN 'Needs Monitoring'
        ELSE 'Performing Well'
    END AS Recommendation
FROM `fedex_shipments.xlsx`
GROUP BY Route_ID;

-- TASK 4 – Warehouse Performance --

-- Query 4.1 – Top 3 Warehouses with Highest Average Delay
SELECT
    Warehouse_ID,
    ROUND(AVG(Delay_Hours),2) AS Average_Delay
FROM `fedex_shipments.xlsx`
GROUP BY Warehouse_ID
ORDER BY Average_Delay DESC
LIMIT 3;

-- Query 4.2 – Total Shipments vs Delayed Shipments
SELECT
    Warehouse_ID,
    COUNT(*) AS Total_Shipments,
    SUM(
        CASE
            WHEN Delay_Hours > 0 THEN 1
            ELSE 0
        END
    ) AS Delayed_Shipments
FROM `fedex_shipments.xlsx`
GROUP BY Warehouse_ID;

-- Query 4.3 – Warehouses Above Global Average Delay (CTE)
WITH AvgDelay AS
(
    SELECT AVG(Delay_Hours) AS Global_Avg
    FROM `fedex_shipments.xlsx`
)

SELECT
    Warehouse_ID,
    ROUND(AVG(Delay_Hours),2) AS Warehouse_Avg_Delay
FROM `fedex_shipments.xlsx`
GROUP BY Warehouse_ID
HAVING AVG(Delay_Hours) >
(
    SELECT Global_Avg
    FROM AvgDelay
);

-- Query 4.4 – Rank Warehouses by On-Time Delivery %
SELECT
    Warehouse_ID,
    ROUND(
        SUM(
            CASE
                WHEN Delay_Hours = 0 THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS On_Time_Percentage
FROM `fedex_shipments.xlsx`
GROUP BY Warehouse_ID
ORDER BY On_Time_Percentage DESC;

-- TASK 5 – Delivery Agent Performance 

-- Query 5.1 – Rank Delivery Agents by On-Time Delivery %
SELECT
    Agent_ID,
    ROUND(
        SUM(CASE WHEN Delay_Hours = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS On_Time_Percentage,
    DENSE_RANK() OVER(
        ORDER BY
        SUM(CASE WHEN Delay_Hours = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) DESC
    ) AS Agent_Rank
FROM `fedex_shipments.xlsx`
GROUP BY Agent_ID;

-- Query 5.2 – Find Agents Below 85% On-Time Delivery
SELECT
    Agent_ID,
    ROUND(
        SUM(CASE WHEN Delay_Hours = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS On_Time_Percentage
FROM `fedex_shipments.xlsx`
GROUP BY Agent_ID
HAVING On_Time_Percentage < 85;

-- Query 5.3 – Compare Top 5 vs Bottom 5 Agents (Rating & Experience)
(
SELECT
    Agent_ID,
    Agent_Name,
    Avg_Rating,
    Experience_Years
FROM `fedex_delivery_agents.xlsx`
ORDER BY Avg_Rating DESC
LIMIT 5
)

UNION ALL

(
SELECT
    Agent_ID,
    Agent_Name,
    Avg_Rating,
    Experience_Years
FROM `fedex_delivery_agents.xlsx`
ORDER BY Avg_Rating ASC
LIMIT 5
);

-- Query 5.4 – Training Recommendation
SELECT
    Agent_ID,
    Agent_Name,
    Avg_Rating,
    Experience_Years,
    CASE
        WHEN Avg_Rating < 4.0
             AND Experience_Years < 3
             THEN 'Training Required'

        WHEN Avg_Rating < 4.0
             THEN 'Performance Review'

        ELSE 'Good Performance'
    END AS Recommendation
FROM `fedex_delivery_agents.xlsx`;


-- TASK 6 – Shipment Tracking Analytics

-- Query 6.1 – Latest Shipment Status with Delivery Date
SELECT
    Shipment_ID,
    Order_ID,
    Delivery_Status,
    Delivery_Date
FROM `fedex_shipments.xlsx`
ORDER BY STR_TO_DATE(Delivery_Date,'%Y-%m-%d %H:%i:%s') DESC;

-- Query 6.2 – Routes with Majority of Shipments "In Transit" or "Returned"
SELECT
    Route_ID,
    Delivery_Status,
    COUNT(*) AS Total_Shipments
FROM `fedex_shipments.xlsx`
WHERE Delivery_Status IN ('In Transit','Returned')
GROUP BY Route_ID, Delivery_Status
ORDER BY Total_Shipments DESC;

-- Query 6.3 – Most Frequent Delay Status
SELECT
    Delivery_Status,
    COUNT(*) AS Total
FROM `fedex_shipments.xlsx`
GROUP BY Delivery_Status
ORDER BY Total DESC;

 -- Query 6.4 – Orders with Delay Greater Than 120 Hours
 SELECT
    Shipment_ID,
    Order_ID,
    Route_ID,
    Delay_Hours
FROM `fedex_shipments.xlsx`
WHERE Delay_Hours > 120
ORDER BY Delay_Hours DESC;


-- TASK 7 – Advanced KPI Reporting

-- Query 7.1 – Average Delivery Delay per Source Country
SELECT
    r.Source_Country,
    ROUND(AVG(s.Delay_Hours),2) AS Average_Delay_Hours
FROM `fedex_shipments.xlsx` s
JOIN `fedex_routes.xlsx` r
ON s.Route_ID = r.Route_ID
GROUP BY r.Source_Country
ORDER BY Average_Delay_Hours DESC;

-- Query 7.2 – On-Time Delivery Percentage
SELECT
    ROUND(
        SUM(CASE WHEN Delay_Hours = 0 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS On_Time_Delivery_Percentage
FROM `fedex_shipments.xlsx`;
 
-- Query 7.3 – Average Delay per Route
SELECT
    Route_ID,
    ROUND(AVG(Delay_Hours),2) AS Average_Delay_Hours
FROM `fedex_shipments.xlsx`
GROUP BY Route_ID
ORDER BY Average_Delay_Hours DESC;

-- Query 7.4 – Warehouse Utilization Percentage
SELECT
    w.Warehouse_ID,
    w.City,
    w.Capacity_per_day,
    COUNT(s.Shipment_ID) AS Shipments_Handled,
    ROUND(
        COUNT(s.Shipment_ID) * 100.0 / w.Capacity_per_day,
        2
    ) AS Warehouse_Utilization_Percentage
FROM `fedex_warehouses.xlsx` w
LEFT JOIN `fedex_shipments.xlsx` s
ON w.Warehouse_ID = s.Warehouse_ID
GROUP BY
    w.Warehouse_ID,
    w.City,
    w.Capacity_per_day
ORDER BY Warehouse_Utilization_Percentage DESC;


