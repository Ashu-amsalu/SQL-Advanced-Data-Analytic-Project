
-- ============================================
--Task 1. What percentage of total sales comes from the top 10% of customers?
-- ============================================

    WITH CustomerSales AS (
        SELECT 
            c.customer_key,
            SUM(s.sales) AS total_sales
        FROM gold.fact_sales AS s
        LEFT JOIN gold.dim_customers AS c 
            ON s.customer_key = c.customer_key
        GROUP BY c.customer_key
    ),
    Ranked AS (
        SELECT 
            total_sales,
            NTILE(10) OVER (ORDER BY total_sales DESC) AS decile
        FROM CustomerSales
    )
    SELECT 
        SUM(CASE WHEN decile = 1 THEN total_sales ELSE 0 END) * 1.0 / SUM(total_sales) AS top10_pct_share
    FROM Ranked;

-- ============================================
--Task 2. How much do male vs. female customers contribute to overall reven
-- ============================================

    SELECT
        c.gender,
        SUM(s.sales) AS total_sales,
        SUM(sales)*100/SUM(SUM(sales)) OVER() AS percent_contribution
    FROM gold.fact_sales AS s
    LEFT JOIN gold.dim_customers AS c
        ON s.customer_key = c.customer_key
    GROUP BY c.gender
    ORDER BY total_sales DESC;

-- ============================================
--Task 3. What share of total revenue does each product category contribute?
-- ============================================
   
    SELECT
        p.category,
        SUM(s.sales) AS total_revenue,
        ROUND(SUM(s.sales) * 100.0 / SUM(SUM(s.sales)) OVER(),2) AS percent_contribution
    FROM gold.fact_sales AS s
    LEFT JOIN gold.dim_products AS p
        ON s.product_key = p.product_key
    GROUP BY p.category
    ORDER BY total_revenue DESC;

-- ============================================
--Task 4. Which subcategory accounts for the highest percentage of revenue within each category?
-- ============================================

    WITH aggregation AS (
        SELECT 
            p.category,
            p.subcategory,
            SUM(s.sales)  AS total_revenu,
           ROUND(SUM(s.sales)*100.0/SUM(SUM(s.sales)) OVER (PARTITION BY p.category),2) AS percent_countribution  
        FROM gold.fact_sales AS s
        LEFT JOIN gold.dim_products AS p
            ON s.product_key = p.product_key
        GROUP BY  p.category,p.subcategory
        )
        ,ranking AS (
        SELECT
            *,
            RANK() OVER(PARTITION BY category ORDER BY percent_countribution DESC) AS rank_list
        FROM aggregation
        )
        SELECT
            category,
            subcategory,
            total_revenu,
            percent_countribution,
            rank_list
        FROM ranking
        WHERE rank_list =1
        ORDER BY percent_countribution DESC
   
-- ============================================
--Task 5. What percentage of revenue comes from the top 5 best-selling products?
-- ============================================

    WITH aggregation AS(
        SELECT TOP 5
            p.product_name,
            SUM(s.sales) AS total_revenu,
            ROUND( SUM(s.sales)*100.0/SUM(SUM(s.sales)) OVER(),2) AS percent_contri
            FROM gold.fact_sales AS s
        LEFT JOIN gold.dim_products AS P
            ON s.product_key = p.product_key
        GROUP BY p.product_name
        ORDER BY total_revenu DESC
        )
        ,top5_total AS(
        SELECT 
            SUM(percent_contri) AS top5_percent
        FROM aggregation
        )
        SELECT*FROM  top5_total

-- ============================================
--Task 6. What is the percentage share of sales by country?
-- ============================================

    SELECT
        c.country,
        SUM(s.sales) AS total_sales,
        SUM(s.sales)*100.0/ SUM(SUM(s.sales)) OVER() AS percent_sales_share
    FROM gold.fact_sales AS s
    LEFT JOIN gold.dim_customers AS c
        ON s.customer_key = c.customer_key
    GROUP BY c.country
    ORDER BY percent_sales_share DESC

-- ============================================
--Task 7. Which product categories contribute the largest share of profit (sales – maintenance cost)?
-- ============================================

    SELECT
        p.category,
         SUM(s.sales) AS total_revenue,
        SUM(s.sales - (p.product_cost * s.quantity)) AS profit_share
    From gold.fact_sales AS S
    LEFT JOIN gold.dim_products AS p
        ON s.product_key =p.product_key
    GROUP BY p.category
    ORDER BY profit_share DESC

-- ============================================
--Task 8. How much of the total revenue is consumed by maintenance cost?
-- ============================================

    SELECT 
        SUM(product_cost) AS total_maintenance_cost
    FROM gold.dim_products
