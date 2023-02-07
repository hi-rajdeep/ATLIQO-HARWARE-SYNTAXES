SELECT * FROM DIM_CUSTOMER;
SELECT * FROM DIM_PRODUCT;
SELECT * FROM fact_gross_price;
SELECT * FROM fact_manufacturing_cost;
SELECT * FROM fact_pre_invoice_deductions;
SELECT * FROM fact_sales_monthly;
/*Requests:*/
/*1. Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region.*/
select MARKET
FROM dim_customer
WHERE customer ="Atliq Exclusive" AND region = "APAC";

/*2. What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg*/

WITH CTE AS (SELECT COUNT(DISTINCT product_code) AS UNIQUE_PRODUCTS_2020
FROM fact_sales_monthly
WHERE FISCAL_YEAR = 2020),

CTE2 AS (SELECT COUNT(DISTINCT product_code)AS UNIQUE_PRODUCTS_2021
FROM fact_sales_monthly
WHERE FISCAL_YEAR = 2021)

SELECT UNIQUE_PRODUCTS_2020, UNIQUE_PRODUCTS_2021, 
concat(ROUND((((UNIQUE_PRODUCTS_2021 - UNIQUE_PRODUCTS_2020)/UNIQUE_PRODUCTS_2020)*100),2),"%") AS PERCENTAGE_CHG
FROM CTE JOIN CTE2;


/*3. Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count*/

SELECT SEGMENT, COUNT(DISTINCT(PRODUCT)) AS PRODUCT_COUNT
FROM dim_product
group by SEGMENT
ORDER BY PRODUCT_COUNT DESC;

/*4. Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference*/


select segment , sum(if(fiscal_year = 2020 , 1,0)) as product_count_2020,
sum(if(fiscal_year = 2021 , 1,0)) as product_count_2021,
(sum(if(fiscal_year = 2021 , 1,0))) - ((sum(if(fiscal_year = 2020 , 1,0))))  as difference
from (select  distinct f.product_code,d.segment, f.fiscal_year
from dim_product d inner join fact_gross_price f
using( product_code )) as tt
where fiscal_year in(2020,2021)
group by segment;

/*5. Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost*/

select product_code, product, manufacturing_cost 
from dim_product  join fact_manufacturing_cost
using(product_code)
where manufacturing_cost= ( select min(manufacturing_cost) from fact_manufacturing_cost)

union

select product_code, product, manufacturing_cost 
from dim_product  join fact_manufacturing_cost
using(product_code)
where manufacturing_cost= ( select max(manufacturing_cost) from fact_manufacturing_cost);

/*6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage*/

select customer_code, customer, concat(round((avg(pre_invoice_discount_pct)*100),2),'%') as average_discount_percentage
from fact_pre_invoice_deductions inner join dim_customer
using (customer_code)
where fiscal_year = 2021 and market = 'india'
group by customer_code
order by avg(pre_invoice_discount_pct) desc
limit 5;	

/*7. Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount*/

select monthname(fsm.date) as month_, year(fsm.date) as year_, round(sum(fgp.gross_price * fsm.sold_quantity),2) as gross_sales_amount
from fact_sales_monthly fsm inner join fact_gross_price fgp using (product_code)
inner join dim_customer dc using (customer_code)
where customer = 'Atliq Exclusive'
group by year_, month_
order by gross_sales_amount desc;

/*8. In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity*/

select quarter(date)as quarter_ , sum(sold_quantity)
from fact_sales_monthly
where fiscal_year = 2020
group by quarter(date)
order by sum(sold_quantity) desc
limit 1;

/*9. Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage*/

with cte as (select dc.channel, round(sum(fgp.gross_price * fsm.sold_quantity),2) as gross_sales_mln
from dim_customer dc inner join fact_sales_monthly fsm using(customer_code)
inner join fact_gross_price fgp using(product_code)
where fsm.fiscal_year= 2021
group by dc.channel)

select channel, gross_sales_mln, concat(round((gross_sales_mln/ sum(gross_sales_mln) over() *100),2),'%') as percentage
from cte
order by percentage desc;

/*10. Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
division
product_code
product
total_sold_quantity
rank_order*/

with cte as (select division, product_code, product, sum(sold_quantity) as total_sold_quantity,
dense_rank() over (partition by division order by sum(sold_quantity) desc) as rank_order
from dim_product join fact_sales_monthly
using (product_code)
where fiscal_year= 2021
group by division,product_code)

select * from cte
where rank_order <4;
