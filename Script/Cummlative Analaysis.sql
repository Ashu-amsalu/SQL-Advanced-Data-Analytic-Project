

-- ============================================
-- Task 1: Cumulative revenue over time (month by month)
-- ============================================
    SELECT
        YEAR(order_date) AS order_year, -- year of the order
        MONTH(order_date) AS order_month, -- month of the order
        SUM(sales) AS monthly_revenue, -- total revenue for the month
        SUM(SUM(sales)) OVER (PARTITION BY YEAR(order_date) ORDER BY MONTH(order_date)) AS cumulative_revenue -- running total revenue within the year
    FROM gold.fact_sales
    GROUP BY YEAR(order_date), MONTH(order_date)
    HAVING YEAR(order_date) IS NOT NULL
    ORDER BY order_year, order_month;

-- ============================================
-- Task 2: Cumulative number of customers acquired over time
-- ============================================
    WITH firstpurchase AS (
    SELECT
        customer_key, -- unique customer identifier
        MIN(order_date) AS first_order_date -- first purchase date per customer
    FROM gold.fact_sales
    GROUP BY customer_key
    ),
    cumulative AS (
    SELECT
        YEAR(first_order_date) AS order_year, -- year of first purchase
        MONTH(first_order_date) AS order_month, -- month of first purchase
        COUNT(customer_key) AS new_customer, -- number of new customers in that month
        SUM(COUNT(customer_key)) OVER (ORDER BY YEAR(first_order_date), MONTH(first_order_date)) AS cumulative_customer -- running total of customers acquired
    FROM firstpurchase
    GROUP BY YEAR(first_order_date), MONTH(first_order_date)
    )
    SELECT *
    FROM cumulative
    WHERE order_year IS NOT NULL
    ORDER BY order_year, order_month;

-- ============================================
-- Task 3: Cumulative sales by product category
-- ============================================
    SELECT
        p.category, -- product category
        YEAR(s.order_date) AS order_year, -- year of order
        MONTH(s.order_date) AS order_month, -- month of order
        SUM(s.sales) AS monthly_revenue, -- revenue for this category in the month
        SUM(SUM(s.sales)) OVER (PARTITION BY p.category, YEAR(s.order_date)ORDER BY MONTH(s.order_date)) AS cumulative_revenue -- running total revenue per category within the year
    FROM gold.fact_sales AS s
    LEFT JOIN gold.dim_products AS p
    ON s.product_key = p.product_key
    GROUP BY p.category, YEAR(s.order_date), MONTH(s.order_date)
    HAVING YEAR(s.order_date) IS NOT NULL
    ORDER BY p.category, order_year, order_month;

-- ============================================
-- Task 4: Cumulative revenue per customer
-- ============================================
    SELECT 
        s.customer_key, -- unique customer identifier
        c.firstname,    -- customer first name
        c.lastname,     -- customer last name
        s.order_date,   -- order date
        SUM(s.sales) OVER (PARTITION BY s.customer_key  ORDER BY s.order_date) AS cumulative_revenue_per_customer -- running total revenue per customer
    FROM gold.fact_sales AS s
    JOIN gold.dim_customers AS c 
    ON s.customer_key = c.customer_key
    ORDER BY s.customer_key, s.order_date;

-- ============================================
-- Task 5: Cumulative order count vs shipping completion
-- ============================================
    SELECT
        YEAR(order_date) AS order_year, -- order year
        MONTH(order_date) AS order_month, -- order month
        COUNT(order_number) AS orders_placed, -- total orders placed in month
        COUNT(CASE WHEN ship_date IS NOT NULL THEN order_number END) AS orders_shipped, -- total shipped
        SUM(COUNT(order_number)) OVER (ORDER BY YEAR(order_date), MONTH(order_date)) AS cumulative_order, -- running total orders placed
        SUM(COUNT(CASE WHEN ship_date IS NOT NULL THEN order_number END)) OVER (ORDER BY YEAR(order_date), MONTH(order_date)) AS cumulative_shipped -- running total shipped orders
    FROM gold.fact_sales
    GROUP BY YEAR(order_date), MONTH(order_date)
    HAVING YEAR(order_date) IS NOT NULL
    ORDER BY order_year, order_month;

-- ============================================
-- Task 6: Cumulative revenue per country
-- ============================================
    SELECT
        c.country, -- customer country
        YEAR(s.order_date) AS order_year, -- year of order
        MONTH(s.order_date) AS order_month, -- month of order
        SUM(s.sales) AS monthly_revenue, -- revenue in that month for the country
        SUM(SUM(s.sales)) OVER (PARTITION BY c.country, YEAR(s.order_date)ORDER BY MONTH(s.order_date)) AS cumulative_revenue_per_country -- running total revenue per country
    FROM gold.fact_sales AS s
    LEFT JOIN gold.dim_customers AS c
        ON s.customer_key = c.customer_key
    GROUP BY c.country, YEAR(s.order_date), MONTH(s.order_date)
    HAVING YEAR(s.order_date) IS NOT NULL
    ORDER BY order_year, order_month;

-- ============================================
-- Task 7: Cumulative revenue by product line
-- ============================================
    SELECT
        p.product_line, -- product line category
        YEAR(s.order_date) AS order_year, -- year of order
        MONTH(s.order_date) AS order_month, -- month of order
        SUM(s.sales) AS monthly_revenue, -- revenue in that month for the product line
        SUM(SUM(s.sales)) OVER (PARTITION BY p.product_line ORDER BY YEAR(s.order_date), MONTH(s.order_date)) AS cumulative_revenue -- running total revenue for the product line
    FROM gold.fact_sales AS s
    LEFT JOIN gold.dim_products AS p
    ON s.product_key = p.product_key
    GROUP BY p.product_line, YEAR(s.order_date), MONTH(s.order_date)
    HAVING YEAR(s.order_date) IS NOT NULL
    ORDER BY order_year, order_month;
