WITH locations AS (
  SELECT
    *
  FROM {{ ref('jaffle_shop', 'locations') }}
), orders AS (
  /* Order overview data mart, offering key details for each order inlcluding if it's a customer's first order and a food vs. drink item breakdown. One row per order. */
  SELECT
    *
  FROM {{ ref('jaffle_shop', 'orders') }}
), join_1 AS (
  SELECT
    locations.location_id,
    locations.location_name,
    locations.tax_rate,
    locations.opened_date,
    orders.order_id,
    orders.customer_id,
    orders.subtotal_cents,
    orders.tax_paid_cents,
    orders.order_total_cents,
    orders.subtotal,
    orders.tax_paid,
    orders.order_total,
    orders.ordered_at,
    orders.order_cost,
    orders.order_items_subtotal,
    orders.count_food_items,
    orders.count_drink_items,
    orders.count_order_items,
    orders.is_food_order,
    orders.is_drink_order,
    orders.customer_order_number
  FROM locations
  LEFT JOIN orders
    ON locations.location_id = orders.location_id
), aggregate_1 AS (
  SELECT
    location_id,
    location_name,
    tax_rate,
    opened_date,
    COUNT_BIG(order_id) AS total_orders,
    SUM(order_total) AS total_revenue,
    SUM(order_cost) AS total_cost,
    AVG(order_total) AS average_order_value
  FROM join_1
  GROUP BY
    location_id,
    location_name,
    tax_rate,
    opened_date
), formula_1 AS (
  SELECT
    *,
    total_revenue - total_cost AS gross_profit
  FROM aggregate_1
), location_profitability_canvas_v1_sql AS (
  /* Location-level profitability summary created in dbt Canvas.
Includes order count, revenue, cost, average order value,
and gross profit metrics. */
  SELECT
    *
  FROM formula_1
)
SELECT
  *
FROM location_profitability_canvas_v1_sql