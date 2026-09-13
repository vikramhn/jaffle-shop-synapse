WITH location_profitability_v1 AS (
  /* Location-level profitability summary with one row per location. */
  SELECT
    *
  FROM {{ ref('jaffle_shop', 'location_profitability_v1') }}
), location_profitability_canvas_v1_sql AS (
  SELECT
    *
  FROM location_profitability_v1
)
SELECT
  *
FROM location_profitability_canvas_v1_sql