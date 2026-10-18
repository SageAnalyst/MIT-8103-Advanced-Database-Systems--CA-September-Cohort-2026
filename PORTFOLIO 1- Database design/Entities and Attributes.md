Entities and Attributes


1. Product Details


Stores master catalog information about apparel styles, color profiles, sizing variants, and commercial introduction dates.


Attributes:
* collection_id
* Product_name
* Product_color
* Product_size
* Launch_date


Primary Key:
* collection_id




2. Sales


Stores transactional order records, batch quantities sold, unit prices, and purchase dates for each apparel line.


Attributes:


* Collection_id
* Order_date
* Quantity_sold
* Price_each


Primary Key:
 (collection_id, Order_date)


Foreign Key:
 collection_id references Products_dets


 3. Location


Stores delivery destinations, recipient street addresses, administrative states, and calculated logistics delivery fees.


Attributes:


* collection_id
* Order_address
* State
* Delivery_fee


Primary Key:
(collection_id, order_address)


Foreign Key:
 collection_id references Products_dets


 4. Outreach 


Stores marketing and publicity attribution data linking customer delivery destinations to the digital discovery channel used.


Attributes:


* collection_id
* order_address
* Outreach


Primary Key:
(collection_id, order_address)


Foreign Key:
 collection_id references Products_dets
