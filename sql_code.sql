# PROJECT: Sample SQL queries I wrote for a self-learning project I worked on. 
# The ERD diagram has been uploaded in the same GitHub repository which shows the relation between the different tables.
# The queries include advanced functions such as making subqueries, temp tables, CASE statements, JOINs, data cleaning with DATE_TRUNC, and WINDOW functions. 

# 1- How many of the sales reps have more than 5 accounts that they manage?

SELECT COUNT(*) num_reps_above
FROM(SELECT s.id, s.name, COUNT(*) num_accounts
     FROM accounts a
     JOIN sales_reps s
     ON s.id = a.sales_rep_id
     GROUP BY s.id, s.name
     HAVING COUNT(*) > 5
     ORDER BY num_accounts) AS t1;


# 2- In which month of which year did Walmart spend the most on gloss paper in terms of dollars?

SELECT DATE_TRUNC('month', o.occurred_at) ord_date, SUM(o.gloss_amt_usd) tot_spent
FROM orders o 
JOIN accounts a
ON a.id = o.account_id
WHERE a.name = 'Walmart'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;


# 3- identify top performing sales reps, which are sales reps associated with more than 200 orders. Create a table with the sales rep name, the total number of orders, and a column with top or not depending on if they have more than 200 orders. Place the top sales people first in your final table.

SELECT s.name, COUNT(*) num_ords,
     CASE WHEN COUNT(*) > 200 THEN 'top'
     ELSE 'not' END AS sales_rep_level
FROM orders o
JOIN accounts a
ON o.account_id = a.id 
JOIN sales_reps s
ON s.id = a.sales_rep_id
GROUP BY s.name
ORDER BY 2 DESC;


# 4- Provide the name of the sales_rep in each region with the largest amount of total_amt_usd sales.

SELECT t3.rep_name, t3.region_name, t3.total_amt
FROM(SELECT region_name, MAX(total_amt) total_amt
     FROM(SELECT s.name rep_name, r.name region_name, SUM(o.total_amt_usd) total_amt
             FROM sales_reps s
             JOIN accounts a
             ON a.sales_rep_id = s.id
             JOIN orders o
             ON o.account_id = a.id
             JOIN region r
             ON r.id = s.region_id
             GROUP BY 1, 2) t1
     GROUP BY 1) t2
JOIN (SELECT s.name rep_name, r.name region_name, SUM(o.total_amt_usd) total_amt
     FROM sales_reps s
     JOIN accounts a
     ON a.sales_rep_id = s.id
     JOIN orders o
     ON o.account_id = a.id
     JOIN region r
     ON r.id = s.region_id
     GROUP BY 1,2
     ORDER BY 3 DESC) t3
ON t3.region_name = t2.region_name AND t3.total_amt = t2.total_amt;


# 5- For the region with the largest sales total_amt_usd, how many total orders were placed?

SELECT r.name, COUNT(o.total) total_orders
FROM sales_reps s
JOIN accounts a
ON a.sales_rep_id = s.id
JOIN orders o
ON o.account_id = a.id
JOIN region r
ON r.id = s.region_id
GROUP BY r.name
HAVING SUM(o.total_amt_usd) = (
      SELECT MAX(total_amt)
      FROM (SELECT r.name region_name, SUM(o.total_amt_usd) total_amt
              FROM sales_reps s
              JOIN accounts a
              ON a.sales_rep_id = s.id
              JOIN orders o
              ON o.account_id = a.id
              JOIN region r
              ON r.id = s.region_id
              GROUP BY r.name) sub);


# 6- Provide the name of the sales_rep in each region with the largest amount of total_amt_usd sales

WITH t1 AS (
  SELECT s.name rep_name, r.name region_name, SUM(o.total_amt_usd) total_amt
   FROM sales_reps s
   JOIN accounts a
   ON a.sales_rep_id = s.id
   JOIN orders o
   ON o.account_id = a.id
   JOIN region r
   ON r.id = s.region_id
   GROUP BY 1,2
   ORDER BY 3 DESC), 
t2 AS (
   SELECT region_name, MAX(total_amt) total_amt
   FROM t1
   GROUP BY 1)
SELECT t1.rep_name, t1.region_name, t1.total_amt
FROM t1
JOIN t2
ON t1.region_name = t2.region_name AND t1.total_amt = t2.total_amt;


# 7- Lets write a query to do some data formatting/ cleaning:

WITH t1 AS (SELECT date, LEFT(date, 2) month_num,
SUBSTR(date,4,2) date_num, SUBSTR(date,7,4) year_num
FROM sf_crime_data)
SELECT *, CAST(CONCAT(year_num,'-',month_num,'-',date_num) AS date) AS formatted_date
FROM t1
LIMIT 10


# 8 - ADVANCED SQL - Creating a partitioned running total and using aggregates in window functions

SELECT id,
       account_id,
       standard_qty,
       DATE_TRUNC('month', occurred_at) AS month,
       DENSE_RANK() OVER main_window AS dense_rank,
       SUM(standard_qty) OVER main_window AS sum_std_qty,
       COUNT(standard_qty) OVER main_window AS count_std_qty,
       AVG(standard_qty) OVER main_window AS avg_std_qty,
       MIN(standard_qty) OVER main_window AS min_std_qty,
       MAX(standard_qty) OVER main_window AS max_std_qty
FROM orders
WINDOW main_window AS (PARTITION BY account_id ORDER BY DATE_TRUNC('month', occurred_at))


# 9- Calculating difference between 2 rows using LAG and LEAD functions

SELECT account_id,
       standard_sum,
       LAG(standard_sum) OVER (ORDER BY standard_sum) AS lag,
       LEAD(standard_sum) OVER (ORDER BY standard_sum) AS lead,
       standard_sum - LAG(standard_sum) OVER (ORDER BY standard_sum) AS lag_difference,
       LEAD(standard_sum) OVER (ORDER BY standard_sum) - standard_sum AS lead_difference
FROM (
SELECT account_id,
       SUM(standard_qty) AS standard_sum
       FROM orders 
       GROUP BY 1
     ) sub


# 10- Separate the standard_qty based on different percentiles

SELECT id, account_id, occurred_at, standard_qty,
		NTILE(4) OVER (ORDER BY standard_qty desc) AS quartile,
		NTILE(5) OVER (ORDER BY standard_qty desc) AS quintile,
		NTILE(100) OVER (ORDER BY standard_qty desc) AS percentile
FROM orders
ORDER BY standard_qty DESC


# 11 - Using the UNION function to count the number of times each companys name appears:

WITH double_accounts AS (
    SELECT *
      FROM accounts

    UNION ALL

    SELECT *
      FROM accounts
)

SELECT name,
       COUNT(*) AS name_count
 FROM double_accounts 
GROUP BY 1
ORDER BY 2 DESC


# 12- Performance tuning: This is an example where a LIMIT is set within a subquery rather than outside it, to optimize query running time

SELECT account_id,
		SUM(poster_qty) AS sum_poster_qty
FROM (SELECT * FROM orders LIMIT 100) sub
WHERE occurred_at BETWEEN '2016-01-01' AND '2018-01-01'
GROUP BY 1

# Rather than writing something like this:

SELECT account_id,
		SUM(poster_qty) AS sum_poster_qty
FROM orders 
WHERE occurred_at BETWEEN '2016-01-01' AND '2018-01-01'
GROUP BY 1
LIMIT 100