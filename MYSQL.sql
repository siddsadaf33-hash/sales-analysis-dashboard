CREATE  DATABASE RETAIL_1SHOP_db;
USE RETAIL_1SHOP_db;
CREATE TABLE retail_sales1 (
    order_id              INT PRIMARY KEY,
    order_date            DATE,
    customer_id           INT,
    customer_name         VARCHAR(50),
    age                   INT,
    gender                VARCHAR(10),
    region                VARCHAR(20),
    city                  VARCHAR(30),
    product_category      VARCHAR(30),
    product_name          VARCHAR(50),
    quantity              INT,
    unit_price            DECIMAL(12,2),
    discount_pct          DECIMAL(4,2),
    sales_amount          DECIMAL(14,2),
    profit                DECIMAL(14,2),
    shipping_cost         DECIMAL(10,2),
    payment_method        VARCHAR(30),
    customer_satisfaction INT,
    return_flag           TINYINT(1),
    order_status          VARCHAR(20),
    days_to_ship          INT
);
SELECT * FROM cleaned_retail_sales_dataset;

SET SQL_SAFE_UPDATES = 0;

UPDATE cleaned_retail_sales_dataset
SET order_date = STR_TO_DATE(order_date, '%d-%m-%Y');

ALTER TABLE cleaned_retail_sales_dataset
MODIFY order_date DATE;
DESCRIBE cleaned_retail_sales_dataset;
SELECT COUNT(*) FROM cleaned_retail_sales_dataset;
SELECT order_id, COUNT(*) FROM cleaned_retail_sales_dataset
GROUP BY order_id HAVING COUNT(*) > 1;

SELECT 
 sum(order_date IS NULL) AS null_date,
 sum(customer_id IS NULL) AS null_customer,
 sum(sales_amount IS NULL) AS null_sales,
 sum(profit IS NULL) AS null_profit,
 sum(region IS NULL OR region = '') AS null_region
FROM cleaned_retail_sales_dataset;

SELECT return_flag, COUNT(*) FROM cleaned_retail_sales_dataset GROUP BY return_flag;

SELECT order_id, quantity, sales_amount, days_to_ship
FROM cleaned_retail_sales_dataset
WHERE quantity > 100 OR days_to_ship > 30;

CREATE VIEW sales_clean AS
SELECT * FROM cleaned_retail_sales_dataset
WHERE quantity < 999;
SELECT COUNT(*) FROM sales_clean;
SELECT MIN(order_date), MAX(order_date) FROM sales_clean;


# q1 which region earn the most profit?

SELECT region,COUNT(*) AS orders,
       ROUND(SUM(sales_amount),0) AS sales,
       ROUND(SUM(profit),0) AS profit,
       ROUND(SUM(profit)/SUM(sales_amount)*100,1) AS margin_pct
FROM sales_clean
GROuP BY region  ORDER BY profit DESC;      
# Answer: South earns the most profit (about 97.5 lakh, roughly 23% of total profit of 4.30 crore),
# followed by West and North. Central earns the least (73.8 lakh) but has the highest margin (19.2%).
# East has the lowest margin (17.7%).

# Q2 which product categories perform best?
SELECT product_category, COUNT(*) AS orders,
       ROUND(SUM(sales_amount),0) AS sales,
       ROUND(SUM(profit),0) AS profit,
       ROUND(SUM(profit)/SUM(sales_amount)*100,1) AS margin_pct
FROM sales_clean
GROUP BY product_category ORDER BY profit DESC;
# Answer: Electronics earns the most profit (1.67 crore, about 39% of total), just ahead of Furniture (1.60 crore, about 37%).
# Together they generate about 76% of all profit. Beauty has the best margin (45.1%) but earns little. Groceries has the lowest margin (8%).

# q3 do higher discount reduces profit?
SELECT ROUND(discount_pct*100,-1) AS discount_band_pct,
       COUNT(*) AS orders,
       ROUND(AVG(profit),0) AS avg_profit
FROM sales_clean
GROUP BY discount_band_pct ORDER BY discount_band_pct;
# Answer: Yes. Average profit per order is highest at the 10% discount band (11,834) and falls steadily after that,
# to 7,023 at the 40% band, which is about 41% lower. Discounts up to 10% do not hurt profit.

#q4 which categories lose the most to returns or cancellations ?
SELECT product_category, COUNT(*) AS orders,
       ROUND(SUM(order_status IN ('Returned','Cancelled'))/COUNT(*)*100,1) AS loss_pct
FROM sales_clean
GROUP BY product_category ORDER BY loss_pct DESC;
# Answer: Groceries has the highest loss rate (23.9%), followed by Clothing (23.5%) and Electronics (23.2%).
# Beauty is lowest (21.3%). The gap between best and worst is only 2.6 points, so returns and cancellations are a business-wide problem, not a category problem.

# Loss rate by payment method
SELECT payment_method, COUNT(*) AS orders,
       ROUND(SUM(order_status IN ('Returned','Cancelled'))/COUNT(*)*100,1) AS loss_pct
FROM sales_clean
GROUP BY payment_method ORDER BY loss_pct DESC;

#q5 what is the sales trend by year ?
SELECT YEAR(order_date) AS yr, COUNT(*) AS orders,
       ROUND(SUM(sales_amount),0) AS sales,
       ROUND(SUM(profit),0) AS profit
FROM sales_clean
GROUP BY yr ORDER BY yr;
# Answer: Sales grew from 3.84 crore (2020) to 5.07 crore (2024), up about 32%. Profit grew similarly, from 70.0 lakh to 93.2 lakh (up 33%).
# The biggest jump was 2021 (+21%). Sales dipped in 2023 (-5%) and recovered in 2024 (+7%). 2024 is the best year for both sales and profit.

#q6 who are the top 10 customers ?
SELECT customer_id, customer_name, COUNT(*) AS orders,
       ROUND(SUM(sales_amount),0) AS total_spent
FROM sales_clean
GROUP BY customer_id, customer_name
ORDER BY total_spent DESC LIMIT 10;
# Answer: The top customer is Meera Kapoor (ID 8739), who spent 11.83 lakh, followed by Meera Pillai (10.72 lakh) and Rohan Mehta (10.33 lakh).
# All top 10 customers placed only 1 order each, so they are high-value single purchases, not loyal repeat buyers.

# Repeat customers
SELECT customer_id, customer_name, COUNT(*) AS orders,
       ROUND(SUM(sales_amount),0) AS total_spent
FROM sales_clean
GROUP BY customer_id, customer_name
HAVING COUNT(*) > 1
ORDER BY orders DESC, total_spent DESC;

#q7 does slow shipping lower satisfaction?
SELECT days_to_ship, COUNT(*) AS orders,
       ROUND(AVG(customer_satisfaction),2) AS avg_rating
FROM sales_clean
WHERE days_to_ship <= 30
GROUP BY days_to_ship ORDER BY days_to_ship;
# Answer: No. Average satisfaction stays flat at about 3.0 out of 5 whether an order ships in 1 day (3.07) or 10 days (2.96).
# Shipping speed does not explain customer satisfaction. (The 4.50 rating at 0 days is based on only 2 orders and should be ignored.)

# Satisfaction by product category
SELECT product_category, COUNT(*) AS orders,
       ROUND(AVG(customer_satisfaction),2) AS avg_rating
FROM sales_clean
GROUP BY product_category ORDER BY avg_rating DESC;

#q8 which payement methods generate the most sales?
SELECT payment_method, COUNT(*) AS orders,
       ROUND(SUM(sales_amount),0) AS sales,
       ROUND(SUM(profit),0) AS profit
FROM sales_clean
GROUP BY payment_method ORDER BY sales DESC;
# Answer: Cash On Delivery generates the most sales (4.20 crore, about 18% of total) and profit (76.9 lakh), followed by EMI (4.08 crore) and Debit Card (4.04 crore).
# Net Banking is lowest (3.16 crore, about 14%). UPI has the most orders (749) but only the 4th-highest sales, so its orders are smaller in value.