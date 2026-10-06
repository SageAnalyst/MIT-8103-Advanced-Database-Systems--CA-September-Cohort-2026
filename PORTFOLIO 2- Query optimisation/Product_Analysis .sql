USE product_mod;

-- Retrieve Total delivery fees for each State.
SELECT
	SUM(Delivery_fee) as Total_Delivery_Fee, State
FROM 
	location
GROUP BY State
ORDER BY State ASC;
#Report shows that the highest delivery total came from Lagos State at a sum of '59500' and the lowest came from Osun at a sum of '3200', we shall proceed to get more insights into it.

-- Retrieve the number of deliveries for each state.

SELECT
	COUNT(Delivery_fee) as Total_Delivery_Fee, State
FROM 
	location
GROUP BY State
ORDER BY State ASC;

#Report shows that 16 Deliveries were made in Lagos, 1 Delivery was made to Ibadan, 2 Delivery was made to Ogun and 2 Delivery was made to Osun

-- Retrieve the orders with the highest and lowest Delivery Fee respectively and the state they were delivered to.

/* SELECT
 	collection_id, MAX(DISTINCT(Delivery_fee)) AS Highest_delivery_fee, MIN(DISTINCT(Delivery_fee)) AS Lowest_Delivery_fee
 FROM
 	location
 GROUP BY collection_id
 ORDER BY Delivery_fee DESC
 LIMIT 1*/

# For Highest Delivery fee 
SELECT 
	collection_id, Delivery_fee, State
FROM 
	location
ORDER BY Delivery_fee DESC
LIMIT 1;

#From result we can see that the highest delivery fee was '7000' by product 'C020', delivered to Lagos State.

# For Lowest Delivery fee
SELECT 
	collection_id, Delivery_fee, State
FROM 
	location
ORDER BY Delivery_fee ASC
LIMIT 1;

#From result we can see that the lowest delivery fee was '1500' by product 'S013', delivered to Ogun State
    
    
#Next we move on to the outreach to show insights for the media and publicity Team

-- Count the number of orders for each outreach type
#First we retrieve all the outreach types that was used

SELECT 
	DISTINCT(Outreach)
FROM
	outreach;

#From the result we can see that there were 4 outreach type; Whatsapp, Facebook, Instagram, Website.

#Number of Orders for Whatsapp Outreach

SELECT 
	SUM(quantity_sold) as num_of_sales, O.Outreach
FROM 
	sales S
JOIN 
	Outreach O
		ON O.collection_id = S.collection_id WHERE O.Outreach = 'Whatsapp';
        
#From result, 338 orders were closed on whatsapp Outreach

#Number of Orders for Facebook Outreach

SELECT 
	SUM(quantity_sold) as num_of_sales, O.Outreach
FROM 
	sales S
JOIN 
	Outreach O
		ON O.collection_id = S.collection_id AND O.Outreach = 'Facebook';

#From result, 318 orders were closed on Facebook Outreach

#Number of Orders for Instagram Outreach    

SELECT 
	SUM(quantity_sold) as num_of_sales, O.Outreach
FROM 
	sales S
JOIN 
	Outreach O
		ON O.collection_id = S.collection_id AND O.Outreach = 'Instagram';

#From result, 423 orders were closed on Instagram Outreach.

#Number of Orders for Website Outreach

SELECT 
	SUM(quantity_sold) as num_of_sales, O.Outreach
FROM 
	sales S
JOIN 
	Outreach O
		ON O.collection_id = S.collection_id AND O.Outreach = 'Website';
        
#From result, 365 orders were closed on Website Outreach.

#We proceed to get orders with the most common Outreach Type
-- Retrieve the type of outreach that is most frequent

SELECT
	Outreach, COUNT(*) AS Frequency
FROM 
	Outreach
GROUP BY Outreach
ORDER BY Frequency DESC
LIMIT 1;

#Facebook has the most frequency with 10

#Next we move to Product Details Table
-- RETRIEVE A LIST OF ALL PRODUCTS ALONG WITH THEIR DETAILS
SELECT 
	*
FROM 
	products_dets;
 -- RETRIEVE A LIST OF PRODUCTS AND DETAILS LAUNCHED BEFORE THE YEAR 1990
 
 SELECT
	collection_id, Product_name, Product_color, Product_size
FROM
	Products_dets
WHERE YEAR(Launch_date) < '1990';

# 28 out of 92 Products were launched before the year 1990

-- IDENTIFY PRODUCTS WITH THE MOST AND LEAST SALES

#PRODUCT WITH MOST SALES
SELECT 
	 collection_id, quantity_sold
FROM 
	sales
ORDER BY quantity_sold DESC;
/*Product S020 and H020 have the highest sales with 98 quantities sold*/

#RETRIEVE PRODUCT S020 nad H020 Details
SELECT
	Product_name, Product_color, Product_size, Launch_date
FROM
	products_dets
WHERE collection_id = 'H020';
/*Product H020 is a Green Custom Hoodie	of size XXL with launch date 1990-02-14*/

SELECT
	Product_name, Product_color, Product_size, Launch_date
FROM
	products_dets
WHERE collection_id = 'S020';
/*Product S020 is a Green Sweatshirt of size XXL with launch date 1990-02-14*/


#PRODUCTS WITH LEAST SALES
SELECT 
	 collection_id, quantity_sold
FROM 
	sales
ORDER BY quantity_sold ASC;
/*Product C028, S028 and H028 have the least sales with 1 quantity sold*/

#RETRIEVE PRODUCT C028, S028 and H028 Details
SELECT
	Product_name, Product_color, Product_size, Launch_date
FROM
	products_dets
WHERE collection_id = 'C028';
/*Product C028 is an Indigo Cargopants of size XXL with launch date 1989-04-18*/

SELECT
	Product_name, Product_color, Product_size, Launch_date
FROM
	products_dets
WHERE collection_id = 'S028';
/*Product S028 is an Indigo Sweatshirt of size XL with launch date 1990-02-21*/

SELECT
	Product_name, Product_color, Product_size, Launch_date
FROM
	products_dets
WHERE collection_id = 'H028';
/*Product H028 is an Indigo Custom Hoodie of size XL with launch date 1990-02-21*/

#We will be working on insights for the Sales Department

-- CALCULATE THE TOTAL REVENUE GENERATED BY EACH ORDER 
SELECT
	collection_id, sum(quantity_sold * price_each) AS Total_Revenue
FROM
	sales
GROUP BY collection_id
ORDER BY collection_id;

-- DETERMINE THE AVERAGE REVENUE PER PRODUCTS 
/*WITH cte AS(
		SELECT
				sum(quantity_sold * price_each) AS Total_Revenue
		FROM
				sales)*/
DROP TEMPORARY TABLE IF EXISTS Total_Revenue;
CREATE TEMPORARY TABLE Total_Revenue  AS
	SELECT
			 collection_id, SUM(quantity_sold), sum(quantity_sold * price_each) AS Revenue
		FROM
			sales
            GROUP BY collection_id
			ORDER BY collection_id
          ;
	SELECT ROUND(AVG(Revenue), 2)  AS Avg_price_per_unit 
		FROM Total_Revenue ;

#The total Revenue from all Products is #10,751,200, the Average revenue generated on each product is #307,177.14

-- SHOW HOW THE LOCKDOWN PERIOD AFFECTED THE REVENUE(2020)

  #Show the total number of products before the lockdown period
SELECT
	 sum(quantity_sold * price_each) AS Total_Revenue, SUM(Quantity_sold) AS Qty_sold
FROM
	sales
        WHERE YEAR(Order_date) < '2020';
	# Before THE LOCKDOWN 963 products were sold making a revenue of #7,550,700 from the year 2010

     #Show the average sales per year before the lockdown period
DROP TEMPORARY TABLE IF EXISTS Total_Sales;
CREATE TEMPORARY TABLE Total_Sales  AS
	SELECT
			 YEAR(Order_date), SUM(quantity_sold) AS Sales, sum(quantity_sold * price_each) AS Total_Revenue
		FROM
			sales
            WHERE YEAR(Order_date) < "2020"
            GROUP BY Order_date
		    ORDER BY Order_date ASC
          ;
	SELECT  ROUND(AVG(Sales), 2)  AS Avg_sales_per_year, ROUND(AVG(Total_Revenue), 2)  AS Avg_rev_per_year
		FROM Total_Sales ;  
	# Before THE LOCKDOWN the average sales per year was 96.30 making a revenue of #755,070
  
  
  #Show the total number of products during the lockdown period
SELECT
	collection_id, sum(quantity_sold * price_each) AS Total_Revenue, SUM(Quantity_sold) AS Qty_sold
FROM
	sales
        WHERE YEAR(Order_date) = '2020'
GROUP BY collection_id
ORDER BY collection_id ;
# DURING THE LOCKDOWN 35 products were sold making a revenue of #210,000

#Show the total number of products after the lockdown period
SELECT
	 sum(quantity_sold * price_each) AS Total_Revenue, SUM(Quantity_sold) AS Qty_sold
FROM
	sales
        WHERE YEAR(Order_date) > '2020';
# DURING THE LOCKDOWN 445 products were sold making a revenue of #2,990,500

    #Show the average sales per year after the lockdown period
DROP TEMPORARY TABLE IF EXISTS Total_Sales;
CREATE TEMPORARY TABLE Total_Sales  AS
	SELECT
			 YEAR(Order_date), SUM(quantity_sold) AS Sales, sum(quantity_sold * price_each) AS Total_Revenue
		FROM
			sales
            WHERE YEAR(Order_date) > "2020"
            GROUP BY Order_date
		    ORDER BY Order_date ASC
          ;
	SELECT  ROUND(AVG(Sales), 2)  AS Avg_sales_per_year, ROUND(AVG(Total_Revenue), 2)  AS Avg_rev_per_year
		FROM Total_Sales ;
		# Before THE LOCKDOWN the average sales per year was 31.79 making a revenue of #213,607.14

/*Average sales per year dropped after the lockdown*/

  -- IDENTIFY THE MOST POPULAR PRODUCTS COLORS AND SIZES
     #For Product Size popularity we check how the sizes did on sales
SELECT
	PD.Product_size, SUM(S.Quantity_sold) AS Number_of_sales
FROM
	products_dets PD
    JOIN
		sales S
			ON
				S.collection_id = PD.collection_id
GROUP BY Product_size
ORDER BY Product_size DESC;
 
        #For Product Color popularity we check how the Colorss did on sales
SELECT
	PD.Product_color, SUM(S.Quantity_sold) AS Number_of_sales
FROM
	products_dets PD
    JOIN
		sales S
			ON
				S.collection_id = PD.collection_id
GROUP BY Product_color
ORDER BY Product_color DESC;

 -- Analyze the correlation between Outreach type and Sales
SELECT O.Outreach, COUNT(S.collection_id) AS Total_order, SUM(S.quantity_sold) AS Total_sales
FROM outreach O
	JOIN sales S
		ON S.collection_id = O.collection_id
	GROUP BY O.Outreach;
    
-- Calculate the conversion rate from outreach to actual sales as a percentage
SELECT O.Outreach, COUNT(S.collection_id) AS Total_order, SUM(S.quantity_sold)/COUNT(O.collection_id) AS Conversion_rate
		FROM outreach O
	JOIN sales S
		ON S.collection_id = O.collection_id
	GROUP BY O.Outreach;

    

    
		
	





