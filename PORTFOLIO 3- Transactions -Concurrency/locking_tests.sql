USE Product_mod;

-- Ensure isolation level is set to READ COMMITTED or REPEATABLE READ
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;


-- Lost Update Problem

-- Scenario:
-- Product 'S020' (Green Sweatshirt, XXL) has a limited production run.
-- Two warehouse managers (Session 1 and Session 2) concurrently attempt to
-- inspect product availability and log units sold.
--
-- Without locking:
-- Both sessions read the same record simultaneously, perform their own updates,
-- and overwrite each other's changes, leading to lost updates and inconsistent sales counts.
--
-- With Pessimistic Locking (`SELECT ... FOR UPDATE`):
-- Session 1 acquires an Exclusive Lock (X-Lock) on the target row in `Products_dets`.
-- Session 2 is forced into a lock wait state until Session 1 completes with COMMIT or ROLLBACK.

-- SESSION 1: Order Reservation & Inventory Mutation

-- Disable autocommit and begin an explicit transaction
SET autocommit = 0;
START TRANSACTION;

-- Select target item and acquire an Exclusive Row Lock (X-Lock)
SELECT 
    collection_id, 
    Product_name, 
    Product_color, 
    Product_size, 
    Launch_date
FROM Products_dets 
WHERE collection_id = 'S020' 
FOR UPDATE;

-- Simulate order processing workload (e.g., verifying stock & calculating tariff)
-- Session 1 records a sales transaction for 10 units
INSERT INTO sales (collection_id, Quantity_sold, Price_each, Order_date)
VALUES ('S020', 10, 5000, '2026-10-10');



-- Switch to Session 2 and execute its commands below to observe the lock contention.

-- Once Session 2 has been executed and confirmed blocked, finalize Session 1:
COMMIT;

-- Verification for Session 1:
SELECT * FROM sales WHERE collection_id = 'S020' AND Order_date = '2026-10-10';



-- SESSION 2: Concurrent Modification Attempt (Opens in a separate connection/window)

--Open a separate connection, disable autocommit, and begin transaction
SET autocommit = 0;
START TRANSACTION;

-- Attempt to read and lock the same row 'S020'
-- [EXPECTED BEHAVIOR]:
-- This query will NOT return immediately. It will hang in a "Lock Wait" state,
-- waiting for Session 1 to release its exclusive lock.
SELECT 
    collection_id, 
    Product_name, 
    Product_color, 
    Product_size 
FROM Products_dets 
WHERE collection_id = 'S020' 
FOR UPDATE;

-- Once Session 1 issues `COMMIT;`, Session 2 immediately unblocks!
-- Session 2 safely executes its allocation knowing Session 1 has finished:
INSERT INTO sales (collection_id, Quantity_sold, Price_each, Order_date)
VALUES ('S020', 5, 5000, '2026-10-11');

-- Commit Session 2
COMMIT;

-- Verification for Session 2:
SELECT * FROM sales WHERE collection_id = 'S020' AND Order_date = '2026-10-11';


-- DIAGNOSTIC QUERIES: Monitoring Lock Contention in InnoDB
-- (Run in a separate monitoring window while Session 2 is waiting)

-- Check current active transactions, lock states, and waiting threads in MySQL 8.0:
SELECT 
    r.trx_id waiting_trx_id,
    r.trx_mysql_thread_id waiting_thread,
    r.trx_query waiting_query,
    b.trx_id blocking_trx_id,
    b.trx_mysql_thread_id blocking_thread,
    b.trx_query blocking_query
FROM performance_schema.data_lock_waits w
INNER JOIN information_schema.innodb_trx b 
    ON b.trx_id = w.blocking_engine_transaction_id
INNER JOIN information_schema.innodb_trx r 
    ON r.trx_id = w.requesting_engine_transaction_id;

-- Inspect active InnoDB locks:
SELECT 
    ENGINE_TRANSACTION_ID,
    OBJECT_NAME,
    INDEX_NAME,
    LOCK_TYPE,
    LOCK_MODE,
    LOCK_STATUS,
    LOCK_DATA
FROM performance_schema.data_locks
WHERE OBJECT_NAME = 'Products_dets';
