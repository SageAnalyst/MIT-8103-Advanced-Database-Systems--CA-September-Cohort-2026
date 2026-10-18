Normalisation is the formal process of structuring relational schema attributes to eliminate data redundancy, prevent update,
insertion, and deletion anomalies, and enforce data integrity. The schema transition from an Unnormalised Form (UNF) through
to Third Normal Form (3NF) and Boyce-Codd Normal Form (BCNF) is structured as follows.

1. Unnormalised Form (UNF)
In its initial unnormalised state, all apparel attributes, customer transaction logs, delivery destinations, and promotional channels
existed as a single wide flat record containing nested repeating groups:

UNF = {
    collection_id, 
    Product_name, 
    Product_color, 
    Product_size, 
    Launch_date, 
    { Order_date, Quantity_sold, Price_each }, 
    { order_address, State, Delivery_fee, Outreach }
}

Anomalies Present in UNF:
Insertion Anomaly: A new apparel design or SKU (e.g., 'H025', Yellow Hoodie) cannot be logged into the database until a customer actually
places an order for it.

Deletion Anomaly: Deleting the order record of a customer who purchased a rare batch inadvertently deletes the catalog specification, sizing,
and launch date of the product itself.

Update Anomaly: If the base price or description of a hoodie changes, every single historical transaction row containing that product must be
individually updated, risking data discrepancies

2. First Normal Form (1NF)
Requirement: 
Eliminate repeating groups and ensure all attribute values are atomic (indivisible).
Establish a unique primary identifier for every record.

Transformation:
The repeating groups { Order_date, Quantity_sold, Price_each } and { order_address, State, Delivery_fee, Outreach } are flattened into single-valued
tabular rows. Because a product collection can have multiple sales dates and multiple delivery destinations, composite candidate keys are required to 
uniquely distinguish tuples:


Flat_1NF = {
    collection_id, 
    Product_name, 
    Product_color, 
    Product_size, 
    Launch_date, 
    Order_date, 
    Quantity_sold, 
    Price_each, 
    order_address, 
    State, 
    Delivery_fee, 
    Outreach
}
Composite Primary Key Identified: (collection_id, Order_date, order_address)

3. Second Normal Form (2NF)
Requirement:
The relation must be in 1NF.
Eliminate all partial functional dependencies—every non-key attribute must depend on the 
entire composite primary key, not just a subset of it.

Functional Dependency (FD) Analysis:
collection_id{Product_name, Product_color, Product_size, Launch_date}
(Partial Dependency: Attributes depend solely on collection_id, rather than the full key (collection_id, Order_date, order_address)).

(collection_id, Order_date){Quantity_sold, Price_each}
(Transaction volume and unit price depend on the specific product batch and transaction date).

(collection_id, order_address){State, Delivery_fee, Outreach}
(Delivery logistics and marketing touchpoint depend on the product dispatched to a specific recipient address).

Decomposition into 2NF:
The partial dependencies are removed by splitting the table into three distinct relations:

Products_dets (Master Catalog Entity):
Attributes: (collection_id, Product_name, Product_color, Product_size, Launch_date)
Primary Key: collection_id

sales (Transaction Ledger):
Attributes: (collection_id, Order_date, Quantity_sold, Price_each)
Primary Key: (collection_id, Order_date)
Foreign Key: collection_id references Products_dets(collection_id)

Fulfillment_Attribution (Intermediate Entity):
Attributes: (collection_id, order_address, State, Delivery_fee, Outreach)
Primary Key: (collection_id, order_address)
Foreign Key: collection_id references Products_dets(collection_id)

4. Third Normal Form (3NF) & Boyce-Codd Normal Form (BCNF)
Requirement:
The relations must be in 2NF.
Eliminate all transitive functional dependencies—no non-key attribute can depend on another non-key attribute (X→Y where Y→Z).
For every functional dependency X→Y, X must be a superkey (BCNF).

Decomposition into Final 3NF / BCNF Relations:
Products_dets (In 3NF & BCNF):
Schema: { collection_id (PK), Product_name, Product_color, Product_size, Launch_date }
Every non-key attribute depends strictly on the key, the whole key, and nothing but the key.

sales (In 3NF & BCNF):
Schema: { collection_id (PK, FK), Order_date (PK), Quantity_sold, Price_each }
Zero transitive dependencies; pricing and volumes represent immutable transaction facts tied to the composite order key.

location (In 3NF & BCNF):
Schema: { collection_id (PK, FK), order_address (PK), State, Delivery_fee }
Isolates physical logistics routing and shipping fees.

Outreach (In 3NF & BCNF):
Schema: { collection_id (PK, FK), order_address (PK), Outreach }
Isolates customer acquisition channels (WhatsApp, Facebook, Instagram, Website), allowing marketing conversions to be evaluated without joining freight fee records.
