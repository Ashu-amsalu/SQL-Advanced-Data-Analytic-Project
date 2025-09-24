

-- ============================================
-- Task 1. How do sales differ by gender (Male vs. Female)?
-- ============================================
    SELECT 
        c.gender,                              -- Gender of customer
        SUM(s.sales) AS total_sales            -- Total sales grouped by gender
    FROM gold.fact_sales AS s
    LEFT JOIN gold.dim_customers AS c 
        ON s.customer_key = c.customer_key
    GROUP BY c.gender;

-- ============================================
-- Task 2. Which age groups contribute the most to revenue?
-- Age buckets: <25, 25–40, 41–60, 60+
-- ============================================
    SELECT 
        CASE 
            WHEN DATEDIFF(YEAR, c.birth_date, GETDATE()) < 25 THEN '<25'
            WHEN DATEDIFF(YEAR, c.birth_date, GETDATE()) BETWEEN 25 AND 40 THEN '25-40'
            WHEN DATEDIFF(YEAR, c.birth_date, GETDATE()) BETWEEN 41 AND 60 THEN '41-60'
            ELSE '60+'
        END AS age_group,                       -- Derived age group
        SUM(s.sales) AS total_sales             -- Total sales by age group
    FROM gold.fact_sales AS s
    LEFT JOIN gold.dim_customers AS c 
        ON s.customer_key = c.customer_key
    GROUP BY 
        CASE 
            WHEN DATEDIFF(YEAR, c.birth_date, GETDATE()) < 25 THEN '<25'
            WHEN DATEDIFF(YEAR, c.birth_date, GETDATE()) BETWEEN 25 AND 40 THEN '25-40'
            WHEN DATEDIFF(YEAR, c.birth_date, GETDATE()) BETWEEN 41 AND 60 THEN '41-60'
            ELSE '60+'
        END;

-- ============================================
-- Task 3. What is the average sales per customer by marital status?
-- ============================================
    WITH CTE_JOIN AS (
        SELECT
            c.marital_status,                   -- Marital status of customer
            s.sales,                            -- Individual sales amount
            c.customer_id                       -- Unique customer identifier
        FROM gold.fact_sales AS s
        LEFT JOIN gold.dim_customers AS c
            ON s.customer_key = c.customer_key
    ),
    aggregation AS (
        SELECT
            marital_status,
            SUM(sales) AS total_sales,          -- Total sales per marital status
            COUNT(DISTINCT customer_id) AS total_customer, -- Number of unique customers
            SUM(sales)*1.0 / COUNT(DISTINCT customer_id) AS Avg_sales_per_customer -- Avg sales per customer
        FROM CTE_JOIN
        GROUP BY marital_status
    )
    SELECT * FROM aggregation;

-- ============================================
-- Task 4. Which countries have the highest average order value per customer?
-- ============================================
    SELECT
        c.country,                              -- Customer's country
        SUM(s.sales) AS total_sales,            -- Total sales per country
        COUNT(DISTINCT c.customer_id) AS total_customer, -- Number of customers per country
        SUM(s.sales) * 1.0 / COUNT(DISTINCT c.customer_id) AS average_order_value_per_customer
    FROM gold.fact_sales AS s
    LEFT JOIN gold.dim_customers AS c
        ON s.customer_key = c.customer_key
    GROUP BY c.country
    ORDER BY average_order_value_per_customer DESC;

-- ============================================
-- Task 5. Segment customers: one-time vs repeat buyers
-- ============================================
    SELECT 
        CASE 
            WHEN COUNT(DISTINCT s.order_number) = 1 THEN 'One-time Buyer'
            ELSE 'Repeat Buyer'
        END AS customer_type,                   -- Classification of customer
        COUNT(DISTINCT c.customer_key) AS num_customers, -- Number of customers by type
        SUM(s.sales) AS total_sales             -- Sales contribution
    FROM gold.fact_sales AS s
    LEFT JOIN gold.dim_customers AS c 
        ON s.customer_key = c.customer_key
    GROUP BY c.customer_key
    HAVING COUNT(DISTINCT s.order_number) >= 1;

-- ============================================
-- Task 6. Active vs inactive customers (based on last 30 days)
-- ============================================
    SELECT 
        CASE 
            WHEN MAX(s.order_date) >= DATEADD(DAY, -30, GETDATE()) THEN 'Active'
            ELSE 'Inactive'
        END AS customer_status,                 -- Customer activity status
        COUNT(DISTINCT c.customer_key) AS num_customers
    FROM gold.fact_sales AS s
    LEFT JOIN gold.dim_customers AS c 
        ON s.customer_key = c.customer_key
    GROUP BY c.customer_key;

-- ============================================
-- Task 7. Loyal customers (placed orders in every quarter of last year)
-- ============================================
    WITH LastYearOrders AS (
        SELECT 
            c.customer_id,
            CONCAT(c.firstname, ' ' ,c.lastname) AS customer_name,
            DATEPART(QUARTER, s.order_date) AS order_quarter, -- Extract quarter
            DATEPART(YEAR, s.order_date) AS order_year
        FROM gold.fact_sales s
        INNER JOIN gold.dim_customers c 
            ON s.customer_key = c.customer_key
        WHERE DATEPART(YEAR, s.order_date) = 2013
    ),
    QuarterlyActivity AS (
        SELECT 
            customer_id,
            COUNT(DISTINCT order_quarter) AS quarters_ordered -- Unique quarters with orders
        FROM LastYearOrders
        GROUP BY customer_id
    )
    SELECT 
        c.customer_id,
        CONCAT(c.firstname, ' ' ,c.lastname) AS customer_name
    FROM QuarterlyActivity qa
    JOIN gold.dim_customers c 
        ON qa.customer_id = c.customer_id
    WHERE qa.quarters_ordered = 4                -- Customers who ordered every quarter
    ORDER BY customer_name;

-- ============================================
-- Task 8. Revenue distribution across categories and subcategories
-- ============================================
    -- By category
    SELECT 
        p.category,
        SUM(s.sales) AS total_sales
    FROM gold.fact_sales AS s
    LEFT JOIN gold.dim_products AS p 
        ON s.product_key = p.product_key
    GROUP BY p.category
    ORDER BY total_sales DESC;

    -- By subcategory
    SELECT
        p.subcategory,
        SUM(s.sales) AS total_sales
    FROM gold.fact_sales AS s
    LEFT JOIN gold.dim_products AS p 
        ON s.product_key = p.product_key
    GROUP BY p.subcategory
    ORDER BY total_sales DESC;

-- ============================================
-- Task 9. High-revenue but low-margin products
-- ============================================
    SELECT 
        p.product_name,
        SUM(s.sales) AS revenue,                 -- Total revenue
        SUM(s.sales - (p.product_cost * s.quantity)) AS profit -- Profit = sales - cost
    FROM gold.fact_sales AS s
    LEFT JOIN gold.dim_products AS p 
        ON s.product_key = p.product_key
    GROUP BY p.product_name
    HAVING SUM(s.sales) > 1000                   -- Ensure high revenue
       AND SUM(s.sales - (p.product_cost * s.quantity)) < 2000 -- But low profit
    ORDER BY revenue DESC;

-- ============================================
-- Task 10. Highest vs lowest sales contribution by product line
-- ============================================
    WITH CTE_JOIN AS (
        SELECT
            p.product_line, 
            s.sales
        FROM gold.fact_sales AS s
        LEFT JOIN gold.dim_products AS p
            ON s.product_key = p.product_key
    ),
    aggregation AS (
        SELECT 
            product_line,
            MAX(sales) AS highest_sales,         -- Max sales in product line
            MIN(sales) AS lowest_sales           -- Min sales in product line
        FROM CTE_JOIN
        GROUP BY product_line
    )
    SELECT * FROM aggregation
    ORDER BY highest_sales DESC;

-- ============================================
-- Task 11. Top 10 products by revenue within each category
-- ============================================
    WITH CTE_JOIN AS (
        SELECT
            p.category,
            p.product_name,
            s.sales
        FROM gold.fact_sales AS s
        LEFT JOIN gold.dim_products AS p
            ON s.product_key = p.product_key
    ),
    aggregation AS (
        SELECT 
            category,
            product_name,
            SUM(sales) AS total_revenue
        FROM CTE_JOIN
        GROUP BY product_name, category
    ),
    ranking AS (
        SELECT
            *,
            RANK() OVER(PARTITION BY category ORDER BY total_revenue DESC) AS TOP_ranking
        FROM aggregation
    )
    SELECT * 
    FROM ranking
    WHERE TOP_ranking <= 10;

-- ============================================
-- Task 12. Sales percentage contribution by country
-- ============================================
    SELECT 
        c.country,
        SUM(s.sales) AS total_sales,
        SUM(s.sales) * 1.0 / SUM(SUM(s.sales)) OVER() AS percent_of_total, -- Share of total sales
        ROUND(SUM(s.sales) * 1.0 / SUM(SUM(s.sales)) OVER(),2) AS percent_of_total_rounded
    FROM gold.fact_sales AS s
    LEFT JOIN gold.dim_customers AS c
        ON s.customer_key = c.customer_key
    GROUP BY c.country
    ORDER BY total_sales DESC;

-- ============================================
-- Task 13. Customer acquisition rate (last 12 months) by country
-- ============================================
    SELECT 
        c.country,
        COUNT(DISTINCT c.customer_key) AS new_customers
    FROM gold.dim_customers AS c
    LEFT JOIN gold.fact_sales AS s 
        ON c.customer_key = s.customer_key
    WHERE c.customer_key IN (
        SELECT customer_key 
        FROM gold.fact_sales 
        WHERE order_date >= DATEADD(YEAR, -1, GETDATE())
    )
    GROUP BY c.country
    ORDER BY new_customers DESC;

-- ============================================
-- Task 14. Year-over-Year (YoY) sales growth by country
-- ============================================
    WITH yearly_sales AS (
        SELECT 
            c.country,
            YEAR(s.order_date) AS sales_year,
            SUM(s.sales) AS total_sales
        FROM gold.fact_sales s
        LEFT JOIN gold.dim_customers c 
            ON s.customer_key = c.customer_key
        GROUP BY c.country, YEAR(s.order_date)
    ),
    sales_with_growth AS (
        SELECT 
            country,
            sales_year,
            total_sales,
            LAG(total_sales) OVER (PARTITION BY country ORDER BY sales_year) AS prev_year_sales -- Previous year sales
        FROM yearly_sales
    )
    SELECT 
        country,
        sales_year,
        total_sales,
        prev_year_sales,
        CASE 
            WHEN prev_year_sales IS NOT NULL AND prev_year_sales > 0 
            THEN ROUND(((total_sales - prev_year_sales) * 1.0 / prev_year_sales) * 100, 2)
            ELSE NULL
        END AS yoy_growth_percent
    FROM sales_with_growth
    ORDER BY yoy_growth_percent DESC;