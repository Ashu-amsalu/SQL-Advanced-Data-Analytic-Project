

-- ============================================
-- Task 1. What is the total sales amount vs. target (if target table exists) for each month?
-- ============================================
    SELECT 
        FORMAT(order_date, 'yyyy-MM') AS month,  -- Extract year-month from order_date
        SUM(sales) AS total_sales                -- Calculate total sales per month
    FROM gold.fact_sales
    GROUP BY FORMAT(order_date, 'yyyy-MM')
    ORDER BY month;

-- ============================================
-- Task 2. Who are the top 10 customers by total revenue contribution?
-- ============================================
    SELECT TOP 10 
        c.customer_id, 
        c.firstname + ' ' + c.lastname AS customer_name, -- Full customer name
        SUM(s.sales) AS total_revenue                   -- Total revenue contributed by each customer
    FROM gold.fact_sales AS s
    LEFT JOIN gold.dim_customers AS c 
        ON s.customer_key = c.customer_key
    GROUP BY c.customer_id, c.firstname, c.lastname
    ORDER BY total_revenue DESC;

-- ============================================
-- Task 3. Which products have the highest sales quantity and highest revenue?
-- ============================================
    SELECT 
        p.category,                                  -- Product category
        SUM(s.sales) AS total_revenue,               -- Total revenue by category
        SUM(s.quantity) AS total_quantity            -- Total quantity sold by category
    FROM gold.fact_sales AS s
    LEFT JOIN gold.dim_products AS p 
        ON s.product_key = p.product_key
    GROUP BY p.category
    ORDER BY total_revenue DESC;

-- ============================================
-- Task 4. What is the average shipping delay (shipping_date – order_date)?
-- ============================================
    SELECT 
        AVG(DATEDIFF(DAY, order_date, ship_date)) AS avg_shipping_days -- Average days between order & shipping
    FROM gold.fact_sales;

-- ============================================
-- Task 5. Which product categories deliver the highest profit margin (sales – maintenance cost)? 
-- ============================================
    SELECT 
        p.product_line,                                           -- Product line
        SUM(s.sales - (p.product_cost * s.quantity)) AS total_profit, -- Profit = sales - cost
        SUM(s.sales) AS total_revenue                             -- Total revenue per product line
    FROM gold.fact_sales AS s
    LEFT JOIN gold.dim_products AS p 
        ON s.product_key = p.product_key
    GROUP BY p.product_line
    ORDER BY total_profit DESC;

-- ============================================
-- Task 6. Which countries have the highest vs. lowest sales performance?
-- ============================================
    SELECT
        c.country,                           -- Country of the customer
        MAX(s.sales) AS highest_sales,       -- Highest sales in that country
        MIN(s.sales) AS lowest_sales         -- Lowest sales in that country
    FROM gold.fact_sales AS s
    LEFT JOIN gold.dim_customers AS c
        ON s.customer_key = c.customer_key
    GROUP BY c.country;

-- ============================================
-- Task 7. What percentage of total revenue comes from the top 20% of customers? (Pareto rule 80/20)
-- ============================================
    WITH customer_revenue AS (
        SELECT 
            c.customer_id,
            SUM(s.sales) AS total_revenue          -- Total revenue by each customer
        FROM gold.fact_sales AS s
        JOIN gold.dim_customers AS c
            ON s.customer_key = c.customer_key
        GROUP BY c.customer_id
    ),
    ranked AS (
        SELECT 
            customer_id,
            total_revenue,
            NTILE(5) OVER (ORDER BY total_revenue DESC) AS quintile -- Divide customers into 5 equal groups
        FROM customer_revenue
    )
    SELECT 
       ROUND(SUM(CASE WHEN quintile = 1 THEN total_revenue END) * 100.0 / SUM(total_revenue), 2) 
           AS pct_from_top20 -- % revenue from top 20% customers
    FROM ranked;

-- ============================================   
-- Task 8. Which products are generating low sales but high maintenance cost?
-- ============================================ 
    SELECT
        p.product_name,                                      -- Product name
        SUM(s.sales) AS total_sales,                         -- Total sales
        SUM(p.product_cost * s.quantity) AS maintenance_cost, -- Total cost
        SUM(s.sales - (p.product_cost * s.quantity)) AS profit -- Profit per product
    FROM gold.fact_sales AS s
    LEFT JOIN gold.dim_products AS p 
        ON s.product_key = p.product_key
    GROUP BY p.product_name
    ORDER BY total_sales;

-- ============================================ 
-- Task 9. Which customers are high revenue but low margin?
-- ============================================ 
    SELECT 
        CONCAT(c.firstname, ' ', c.lastname) AS customer_name, -- Full customer name
        SUM(s.sales) AS total_revenue,                        -- Total sales (revenue)
        SUM(s.sales - (p.product_cost * s.quantity)) AS total_profit -- Profit contribution
    FROM gold.fact_sales AS s 
    LEFT JOIN gold.dim_customers AS c
        ON s.customer_key = c.customer_key
    LEFT JOIN gold.dim_products AS p
        ON s.product_key = p.product_key
    GROUP BY CONCAT(c.firstname, ' ', c.lastname)
    ORDER BY total_profit ASC;  -- Low-margin customers show up first

-- ============================================ 
-- Task 10. Which product categories are showing accelerated vs. declining growth?
-- ============================================ 
    WITH category_sales AS (
        SELECT 
            p.category,                             -- Product category
            YEAR(s.order_date) AS sales_year,       -- Sales year
            SUM(s.sales) AS total_sales             -- Total sales by category & year
        FROM gold.fact_sales AS s
        JOIN gold.dim_products AS p
            ON s.product_key = p.product_key
        GROUP BY p.category, YEAR(s.order_date)
    ),
    category_growth AS (
        SELECT 
            category,
            sales_year,
            total_sales,
            LAG(total_sales) OVER (PARTITION BY category ORDER BY sales_year) AS prev_year_sales -- Prior year sales
        FROM category_sales
    )
    SELECT
        category,
        sales_year,
        total_sales,
        prev_year_sales,
        ROUND(((total_sales - prev_year_sales) * 1.0 / NULLIF(prev_year_sales, 0)) * 100, 2) AS growth_rate -- Growth rate %
    FROM category_growth
    WHERE prev_year_sales IS NOT NULL
    ORDER BY category, sales_year;
