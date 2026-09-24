# Logistics Optimization for Delivery Routes – FedEx

A MySQL-based logistics analytics project focused on analyzing delivery delays, route efficiency, warehouse performance, delivery agent performance, shipment tracking, and logistics KPIs.

## Project Objective

To use SQL and data analytics techniques to identify logistics bottlenecks, evaluate operational performance, and generate data-driven recommendations for improving delivery efficiency.

## Datasets / Tables

- `fedex_orders.xlsx` – Order details, route, warehouse, order amount, delivery type, and payment information.
- `fedex_routes.xlsx` – Source/destination information, distance, and average transit time.
- `fedex_warehouses.xlsx` – Warehouse locations, daily capacity, and manager information.
- `fedex_delivery_agents.xlsx` – Delivery agent zone, experience, and average rating.
- `fedex_shipments.xlsx` – Shipment dates, delivery status, delay hours, and feedback.

## Project Tasks

### Task 1 – Data Cleaning & Preparation
- Duplicate Order ID checks
- Duplicate Shipment ID checks
- NULL value validation
- Date validation
- Route and warehouse reference validation
- Identification of orders without shipment records

### Task 2 – Delivery Delay Analysis
- Delivery delay calculation
- Top delayed routes
- Shipment ranking by delay
- Delivery-type delay comparison

### Task 3 – Route Optimization Insights
- Average transit time analysis
- Average route delay
- Distance-to-time efficiency ratio
- Identification of inefficient routes
- Delayed-route analysis
- Route optimization classification

### Task 4 – Warehouse Performance
- Top warehouses by average delay
- Total vs delayed shipments
- Warehouses above global average delay
- On-time delivery ranking

### Task 5 – Delivery Agent Performance
- Agent ranking by on-time delivery
- Identification of agents below 85% on-time delivery
- Top vs bottom agent comparison
- Training recommendations

### Task 6 – Shipment Tracking Analytics
- Shipment status analysis
- In-transit and returned shipments
- Shipment-status frequency
- Identification of shipments delayed over 120 hours

### Task 7 – Advanced KPI Reporting
- Average delay by source country
- Overall on-time delivery percentage
- Average delay by route
- Warehouse utilization percentage

## SQL Concepts Used

`SELECT` · `WHERE` · `GROUP BY` · `HAVING` · `ORDER BY` · `JOIN` · `LEFT JOIN` · Aggregate Functions · `CASE` · CTEs · Window Functions · `DENSE_RANK()` · `TIMESTAMPDIFF()` · `STR_TO_DATE()`

## Key Findings

- No duplicate Order ID records were identified.
- No duplicate Shipment ID records were identified.
- No NULL `Delay_Hours` records were found.
- No invalid pickup/delivery date relationships were identified.
- Route and warehouse references were validated successfully.
- 16 orders were identified without corresponding shipment records.

## Business Recommendations

1. Review high-delay and low-efficiency routes.
2. Investigate warehouses with higher-than-average delays.
3. Provide targeted support to agents below the 85% on-time delivery threshold.
4. Investigate shipments delayed by more than 120 hours.
5. Monitor route efficiency, on-time delivery, average delay, and warehouse utilization through KPI reporting.

## Tools & Technologies

**MySQL | SQL | MySQL Workbench | Microsoft PowerPoint | GitHub**

## Repository Structure

```text
FedEx-Logistics-Optimization/
│
├── README.md
├── FedEx_Logistics_Project.sql
└── Logistics_Optimization_FedEx.pptx
