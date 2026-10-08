use('product_mod_nosql');


// Pipeline 1: Product Size Performance & Gross Revenue Generation
// Equivalent to relational JOIN across Products_dets and sales grouped by size.
// Deconstructs the nested sales array to compute aggregate demand and revenue.

db.products.aggregate([
  // Step 1: Deconstruct embedded sales_records array into discrete documents
  {
    $unwind: "$sales_records"
  },

  // Step 2: Group by apparel size and aggregate metrics
  {
    $group: {
      _id: "$product_size",
      total_transactions: { $sum: 1 },
      total_units_sold: { $sum: "$sales_records.quantity_sold" },
      gross_revenue: {
        $sum: {
          $multiply: [
            "$sales_records.quantity_sold",
            "$sales_records.price_each"
          ]
        }
      },
      avg_price_per_unit: { $avg: "$sales_records.price_each" }
    }
  },

  // Step 3: Reshape output for business reporting
  {
    $project: {
      _id: 0,
      product_size: "$_id",
      total_transactions: 1,
      total_units_sold: 1,
      gross_revenue: 1,
      avg_price_per_unit: { $round: ["$avg_price_per_unit", 2] }
    }
  },

  // Step 4: Rank sizes by total units transacted
  {
    $sort: { total_units_sold: -1 }
  }
]);


// Pipeline 2: Omni-Channel Marketing Performance & Conversion Volume
// Aggregates nested transaction channel data (WhatsApp, Instagram, Facebook, Website)
// to measure customer acquisition efficiency without multi-table relational joins.

db.products.aggregate([
  // Step 1: Unwind embedded sales history
  {
    $unwind: "$sales_records"
  },

  // Step 2: Group by digital marketing attribution channel
  {
    $group: {
      _id: "$sales_records.channel",
      orders_closed: { $sum: 1 },
      total_units_moved: { $sum: "$sales_records.quantity_sold" },
      channel_revenue: {
        $sum: {
          $multiply: [
            "$sales_records.quantity_sold",
            "$sales_records.price_each"
          ]
        }
      }
    }
  },

  // Step 3: Compute average order batch size per marketing channel
  {
    $project: {
      _id: 0,
      marketing_channel: "$_id",
      orders_closed: 1,
      total_units_moved: 1,
      channel_revenue: 1,
      avg_units_per_order: {
        $round: [{ $divide: ["$total_units_moved", "$orders_closed"] }, 2]
      }
    }
  },

  // Step 4: Sort in descending order by generated revenue
  {
    $sort: { channel_revenue: -1 }
  }
]);


// Pipeline 3: Regional Fulfillment Freight Tariff Analysis
// Evaluates destination logistics metrics by State from the embedded fulfillment subdocument.

db.products.aggregate([
  {
    $unwind: "$sales_records"
  },
  {
    $group: {
      _id: "$sales_records.fulfillment.state",
      deliveries_completed: { $sum: 1 },
      total_freight_fees: { $sum: "$sales_records.fulfillment.delivery_fee" },
      max_delivery_fee: { $max: "$sales_records.fulfillment.delivery_fee" },
      min_delivery_fee: { $min: "$sales_records.fulfillment.delivery_fee" }
    }
  },
  {
    $project: {
      _id: 0,
      state: "$_id",
      deliveries_completed: 1,
      total_freight_fees: 1,
      max_delivery_fee: 1,
      min_delivery_fee: 1
    }
  },
  {
    $sort: { total_freight_fees: -1 }
  }
]);
