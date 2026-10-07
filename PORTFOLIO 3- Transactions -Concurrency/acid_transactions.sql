USE Product_mod;

-- Verify storage engine supports transactions (InnoDB enforces ACID compliance)
SELECT ENGINE, SUPPORT 
FROM information_schema.ENGINES 
WHERE ENGINE = 'InnoDB';


-- SCENARIO: Atomic Retail Order Placement & Fulfillment Dispatch
-- An order is received via Instagram for 2 units of 'H020' (Green Hoodie, XXL)
-- at #8,700 each, shipping to Victoria Island, Lagos with a #3,500 delivery fee.
--
-- Operations to guarantee Atomicity and Consistency across tables:
--  1. Verify product existence in master catalog (`Products_dets`).
--  2. Insert sales entry into `sales`.
--  3. Establish a SAVEPOINT before regional delivery and marketing attribution.
--  4. Insert destination record into `location`.
--  5. Insert marketing source record into `Outreach`.
--  6. Validate operational checks; trigger conditional ROLLBACK if anomalies exist.
--  7. Permanently COMMIT the transaction.
\

DROP PROCEDURE IF EXISTS ProcessOrderTransaction;

DELIMITER $$

CREATE PROCEDURE ProcessOrderTransaction(
    IN p_collection_id CHAR(4),
    IN p_order_address VARCHAR(50),
    IN p_state VARCHAR(14),
    IN p_delivery_fee INT,
    IN p_outreach_channel VARCHAR(16),
    IN p_quantity_sold INT,
    IN p_price_each INT,
    IN p_order_date DATE,
    IN p_simulate_failure BOOLEAN
)
proc_label: BEGIN
    -- SQL Exception handler for automatic abort on catastrophic error
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Atomicity: Revert all uncommitted operations across all tables
        ROLLBACK;
        SELECT 'TRANSACTION FAILED: Database error encountered. Full rollback executed.' AS Transaction_Status;
    END;

    -- 1. Begin explicit transaction boundary
    START TRANSACTION;

    -- 2. Consistency validation: verify referenced product exists in catalog
    IF NOT EXISTS (SELECT 1 FROM Products_dets WHERE collection_id = p_collection_id) THEN
        ROLLBACK;
        SELECT CONCAT('TRANSACTION ABORTED: Product ', p_collection_id, ' does not exist.') AS Transaction_Status;
        LEAVE proc_label;
    END IF;

    -- 3. Atomicity step 1: Log order in `sales`
    INSERT INTO sales (collection_id, Quantity_sold, Price_each, Order_date)
    VALUES (p_collection_id, p_quantity_sold, p_price_each, p_order_date);

    -- 4. Establish an intermediate recovery checkpoint
    SAVEPOINT sp_sales_logged;

    -- 5. Atomicity step 2: Log logistics delivery entry in `location`
    INSERT INTO location (collection_id, order_address, State, Delivery_fee)
    VALUES (p_collection_id, p_order_address, p_state, p_delivery_fee);

    -- 6. Atomicity step 3: Log acquisition attribution in `Outreach`
    INSERT INTO Outreach (order_address, collection_id, Outreach)
    VALUES (p_order_address, p_collection_id, p_outreach_channel);

    -- 7. Conditional validation / Error simulation
    -- If invalid address or simulated courier routing failure occurs:
    IF p_simulate_failure = TRUE THEN
        -- Partial rollback to savepoint: reverts location and outreach, keeps sales log
        ROLLBACK TO SAVEPOINT sp_sales_logged;
        
        -- Complete rollback for testing abort path
        ROLLBACK;
        SELECT 'SIMULATED ERROR TRIGGERED: Partial savepoint reverted and transaction rolled back.' AS Transaction_Status;
        LEAVE proc_label;
    END IF;

    -- 8. Durability: Flush log buffers and commit changes to disk
    COMMIT;
    SELECT 'TRANSACTION SUCCESSFUL: All tables atomically updated and committed.' AS Transaction_Status;

END$$

DELIMITER ;



-- TEST CASE 1: Successful Atomic Transaction (All tables updated and committed)


CALL ProcessOrderTransaction(
    'H020',                                      -- collection_id
    'Plot 14 Victoria Island, Adeola Odeku',     -- order_address
    'Lagos',                                     -- State
    3500,                                        -- Delivery_fee
    'Instagram',                                 -- Outreach
    2,                                           -- Quantity_sold
    8700,                                        -- Price_each
    '2026-10-07',                                -- Order_date
    FALSE                                        -- Simulate failure: FALSE
);

-- Verification: Check that data was written to all tables
SELECT * FROM sales WHERE collection_id = 'H020' AND Order_date = '2026-10-07';
SELECT * FROM location WHERE collection_id = 'H020' AND order_address = 'Plot 14 Victoria Island, Adeola Odeku';
SELECT * FROM Outreach WHERE collection_id = 'H020' AND order_address = 'Plot 14 Victoria Island, Adeola Odeku';


-- TEST CASE 2: Failed Transaction (Rollback demonstrated)


CALL ProcessOrderTransaction(
    'H020',
    'Invalid Route, Marina St',
    'Lagos',
    3500,
    'Whatsapp',
    5,
    8700,
    '2026-10-08',
    TRUE                                         -- Simulate failure: TRUE
);

-- Verification: Ensure no phantom or orphan records were committed
SELECT * FROM sales WHERE collection_id = 'H020' AND Order_date = '2026-10-08';
SELECT * FROM location WHERE collection_id = 'H020' AND order_address = 'Invalid Route, Marina St';
SELECT * FROM Outreach WHERE collection_id = 'H020' AND order_address = 'Invalid Route, Marina St';
