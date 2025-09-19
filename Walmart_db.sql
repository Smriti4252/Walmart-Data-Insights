-- Count total records in Walmart dataset
SELECT COUNT(*) AS total_transactions FROM walmart;

-- Count distinct branches
SELECT COUNT(DISTINCT branch) AS total_branches FROM walmart;

-- Count transactions by payment method
SELECT payment_method, COUNT(*) AS total_transactions
FROM walmart
GROUP BY payment_method



-- 2. Quantity and Transactions by Payment Method
SELECT 
    payment_method,
    COUNT(*) AS total_transactions,
    SUM(quantity) AS total_quantity_sold,
    ROUND(SUM(quantity)/SUM(SUM(quantity)) OVER() * 100, 2) AS percent_of_total_quantity
FROM walmart
GROUP BY payment_method
ORDER BY total_quantity_sold DESC;




-- 4. Busiest Day of the Week per Branch
SELECT branch, day_name, total_transactions
FROM (
    SELECT branch,
           DAYNAME(STR_TO_DATE(date, '%d/%m/%Y')) AS day_name,
           COUNT(*) AS total_transactions,
           RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS `rank`
    FROM walmart
    GROUP BY branch, day_name
) AS ranked
WHERE `rank` = 1
ORDER BY branch;





-- 5. Total Profit per Category
SELECT category,
       SUM(unit_price * quantity * profit_margin) AS total_profit
FROM walmart
GROUP BY category
ORDER BY total_profit DESC;



-- 6. Shift-wise Sales Analysis
SELECT branch,
       CASE 
           WHEN HOUR(TIME(time)) < 12 THEN 'Morning'
           WHEN HOUR(TIME(time)) BETWEEN 12 AND 17 THEN 'Afternoon'
           ELSE 'Evening'
       END AS shift,
       COUNT(*) AS num_transactions,
       SUM(quantity) AS total_quantity
FROM walmart
GROUP BY branch, shift
ORDER BY branch, num_transactions DESC;







-- 8. Preferred Payment Method per Branch
WITH cte AS (
    SELECT branch, payment_method, COUNT(*) AS transactions,
           RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS `rank`
    FROM walmart
    GROUP BY branch, payment_method
)
SELECT branch, payment_method AS preferred_payment_method
FROM cte
WHERE `rank` = 1
ORDER BY branch;




-- 9. Revenue Growth/Loss Trend by Month
WITH monthly_revenue AS (
    SELECT branch,
           YEAR(STR_TO_DATE(date, '%d/%m/%Y')) AS year,
           MONTH(STR_TO_DATE(date, '%d/%m/%Y')) AS month,
           SUM(total) AS revenue
    FROM walmart
    GROUP BY branch, year, month
)
SELECT branch, month,
       MAX(CASE WHEN year = 2022 THEN revenue END) AS revenue_2022,
       MAX(CASE WHEN year = 2023 THEN revenue END) AS revenue_2023,
       ROUND(((MAX(CASE WHEN year = 2023 THEN revenue END) - MAX(CASE WHEN year = 2022 THEN revenue END)) / 
             MAX(CASE WHEN year = 2022 THEN revenue END)) * 100, 2) AS revenue_change_pct
FROM monthly_revenue
GROUP BY branch, month
ORDER BY branch, month;


-- 10. High-Profit but Low-Sales Categories
SELECT category,
       SUM(quantity) AS total_units_sold,
       SUM(unit_price * quantity * profit_margin) AS total_profit,
       ROUND(SUM(unit_price * quantity * profit_margin) / SUM(quantity), 2) AS profit_per_unit
FROM walmart
GROUP BY category
HAVING total_units_sold < 1000
ORDER BY profit_per_unit DESC;



-- 11. Combined Insights Dashboard per Branch
WITH top_category AS (
    SELECT branch, category
    FROM (
        SELECT branch, category, SUM(total) AS revenue,
               RANK() OVER(PARTITION BY branch ORDER BY SUM(total) DESC) AS rnk
        FROM walmart
        GROUP BY branch, category
    ) t
    WHERE rnk = 1
),
preferred_payment AS (
    SELECT branch, payment_method
    FROM (
        SELECT branch, payment_method, COUNT(*) AS cnt,
               RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS rnk
        FROM walmart
        GROUP BY branch, payment_method
    ) t
    WHERE rnk = 1
),
busiest_shift AS (
    SELECT branch, 
           CASE 
               WHEN HOUR(TIME(time)) < 12 THEN 'Morning'
               WHEN HOUR(TIME(time)) BETWEEN 12 AND 17 THEN 'Afternoon'
               ELSE 'Evening'
           END AS shift,
           COUNT(*) AS transactions,
           RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS rnk
    FROM walmart
    GROUP BY branch, shift
)
SELECT t.branch, t.category AS top_category, p.payment_method AS preferred_payment, b.shift AS busiest_shift
FROM top_category t
JOIN preferred_payment p ON t.branch = p.branch
JOIN busiest_shift b ON t.branch = b.branch AND b.rnk = 1;

