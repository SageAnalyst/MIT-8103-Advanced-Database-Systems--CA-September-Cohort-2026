--  Sample Product database
-- Current relational schema by Jamiu Gbadamosi

-- Github; https://github.com/SageAnalyst/MIT-8103-Advanced-Database-Systems---CA-September-Cohort-2026

SELECT 'CREATING DATABASE STRUCTURE' as 'INFO';

/*!50503 set default_storage_engine = InnoDB */;
/*!50503 select CONCAT('storage engine: ', @@default_storage_engine) as INFO */;   

DROP DATABASE IF EXISTS Product_mod;
CREATE DATABASE IF NOT EXISTS Product_mod;
USE Product_mod;

DROP TABLE IF EXISTS Products_dets;
CREATE TABLE IF NOT EXISTS Products_dets
	(
		collection_id   CHAR(4) 					NOT NULL,
        Product_name    VARCHAR(21)					NOT NULL,
        Product_color   VARCHAR(21)					NOT NULL,
        Product_size    ENUM('M','L','XL','XXL')    NOT NULL,
        Launch_date     DATE 						NOT NULL,
        PRIMARY KEY (collection_id)
	);
    
DROP TABLE IF EXISTS sales;
CREATE TABLE IF NOT EXISTS sales
   ( 
	   collection_id  	CHAR(4)			NOT NULL,
       Quantity_sold    INT             NOT NULL,
       Price_each       INT             NOT NULL,
       Order_date       DATE            NOT NULL,
       PRIMARY KEY (collection_id,order_date)
	);
    
DROP TABLE IF EXISTS location;
CREATE TABLE IF NOT EXISTS location
(
	 collection_id  	CHAR(4)			NOT NULL,
     order_address      VARCHAR(50)     NOT NULL,
     State              VARCHAR(14)     NOT NULL,
     Delivery_fee              INT     NOT NULL,
     PRIMARY KEY (collection_id,order_address)
);

DROP TABLE IF EXISTS Outreach;
CREATE TABLE IF NOT EXISTS Outreach
(
	order_address      VARCHAR(50)     NOT NULL,
	collection_id  	   CHAR(4)		   NOT NULL,
    Outreach           VARCHAR(16)     NOT NULL,
    PRIMARY KEY (collection_id,order_address)
);

