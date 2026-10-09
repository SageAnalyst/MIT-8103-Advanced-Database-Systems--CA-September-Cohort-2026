1. Executive Summary

As Xoxho Xpress expands retail fulfillment across southwestern Nigerian commerce hubs, central monolithic database instances experience elevated connection
saturation, write bottlenecks, and cross-region network latency. This report outlines the distributed database strategy for the `Product_mod` platform,
 evaluating horizontal sharding keys, high-availability multi-region replication architectures, and consistency trade-offs defined by the CAP Theorem and PACELC principles.

2. Horizontal Sharding Strategy

To partition the database horizontally, two primary sharding key candidates were evaluated: Catalog-Based Sharding (`collection_id`) versus
 Geographic List-Based Sharding (`State`).

2.1 Comparative Analysis of Sharding Keys

| Evaluation Criteria | Strategy A: Hash Partitioning on `collection_id` | Strategy B: Range/List Partitioning on `State` | Selected Architecture |

| Write Distribution | Uniform hash dispersion across all nodes. | Highly skewed; ~70% of transactions concentrate in Lagos. | Strategy A (`collection_id`) for core inventory. |
| Query Routing | Single-shard lookups for product SKUs and sizing queries. | Requires scatter-gather routing for multi-state catalog searches. | Hash routing avoids cross-shard query storms. |
| Hotspot Risk | Low; apparel drops are distributed across hash slots. | Severe; the Lagos node suffers memory and disk I/O exhaustion. | Strategy A mitigates localized node starvation. |
| Data Locality | Fulfillment queries require global secondary indexes. | High regional locality for courier dispatch hubs. | Hybrid deployment (Catalog: Hash, Logistics: List). |

2.2 Selected Sharding Topology: Hash-Based Partitioning on `collection_id`

Core transactional ledgers (`sales`, `Products_dets`, `location`, `Outreach`) are partitioned across three primary shards using a deterministic hash key:

$$\text{Shard ID} = \text{CRC32}(\text{collection\_id}) \pmod 3$$

Shard 1 (Collection Node A): Stores apparel ranges `H001`–`H030` (Hoodie collections).
Shard 2 (Collection Node B): Stores apparel ranges `C001`–`C030` (Cargopants line).
Shard 3 (Collection Node C): Stores apparel ranges `S001`–`S030` (Sweatshirts & accessories).

sql
-- DDL implementation of horizontal hash partitioning on sales
ALTER TABLE sales PARTITION BY HASH(ASCII(LEFT(collection_id, 1))) PARTITIONS 3;

3. High Availability and Replication Architecture
The cloud infrastructure is hosted within AWS RDS (Relational Database Service) utilizing a hybrid synchronous and asynchronous replication model.

Multi-AZ Synchronous Mirroring (Zero Data Loss)
The primary read/write database in Availability Zone A (Lagos) maintains a synchronous physical standby instance in Availability Zone B.

Every committed transaction write-ahead log (InnoDB redo log) is mirrored to the standby storage layer before acknowledging completion to the client.

Recovery Metrics:

Recovery Point Objective (RPO) = 0: No transactional loss during hardware or network failure.

Recovery Time Objective (RTO) < 60 seconds: Automatic DNS failover promotes the standby node seamlessly.

Asynchronous Regional Read Replicas (Read Offloading)
Read-heavy operational queries (such as periodic Tableau business intelligence reports and customer mobile order tracking) are routed to two asynchronous Read Replicas:

Abuja Regional Hub Replica: Offloads corporate financial reporting without burdening transactional master nodes.

Lagos Island Edge Replica: Serves high-frequency customer catalog browsing.

Replication lag is monitored via Seconds_Behind_Master in MySQL replication diagnostics.

 CAP Theorem and Consistency Model Evaluation
According to Eric Brewer’s CAP Theorem, a distributed data system can simultaneously guarantee at most two of three properties:
 Consistency (C), Availability (A), and Partition Tolerance (P). Because physical network partitions (P) are unavoidable in wide-area cloud networks,
 distributed systems must trade off Consistency versus Availability.

 Consistency (C)
                         /     \
                        /       \
                       /         \
                      /   Xoxho   \
                     /  (Orders)   \
                    /      CP       \
                   /                 \
  Availability (A) ─────────────────── Partition Tolerance (P)
                            
                              Xoxho (Outreach/Clicks)
                                     AP / BASE

CP Classification for Financial and Inventory Transactions
The core ledger modules (Products_dets, sales) enforce a strict CP (Consistency + Partition Tolerance) architecture:

Operational Rationale: Stock overallocation and financial inaccuracies are unacceptable during high-demand apparel drops. If a network partition isolates
 a fulfillment warehouse node from the primary cluster, the partition refuses writes rather than risk inconsistent inventory states.

ACID Guarantees: Strict serializability is prioritized over uptime, preventing double-selling anomalies.

AP / BASE Classification for Digital Outreach Analytics
Marketing channel interactions (Outreach clicks, conversion attribution impressions) adopt an AP (Availability + Partition Tolerance) 
and BASE (Basically Available, Soft State, Eventual Consistency) model:

Operational Rationale: If network connectivity drops between Instagram/WhatsApp lead webhooks and the database,
 dropping promotional clicks hurts attribution metrics.

Eventual Consistency: Outreach logs are queued in resilient messaging brokers (e.g., Apache Kafka / Redis Streams) and asynchronously
 ingested into the database once network links recover, ensuring continuous write availability.


                               

