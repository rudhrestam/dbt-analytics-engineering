# dbt Analytics Engineering (Demo)

![CI](https://github.com/rudhrestam/dbt-analytics-engineering/actions/workflows/ci.yml/badge.svg) ![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

A complete, runnable dbt project: synthetic raw restaurant sales data in DuckDB, modelled staging → intermediate → marts, with schema tests on every layer and a data-quality mart that catches the defects planted in the raw feed.

> ⚠️ **Synthetic data only.** A generator script creates the raw tables with a fixed seed. No real business data — anyone's — is used.

> This is a representative demo of patterns used in production systems, built with original code. It contains no employer code, data, or internal details.

## What it does

```
generate_raw_data.py ──► raw_data (DuckDB): customers · products · orders · order_items
        │
        ▼  dbt build
staging (views)      stg_customers · stg_products · stg_orders · stg_order_items
intermediate (view)  int_order_lines  (lines enriched with order + product context)
marts (tables)       fct_daily_revenue · dim_customers · mart_data_quality
        │
        └── 31 dbt tests: unique · not_null · accepted_values · relationships
```

Design choices worth noting:

- **Revenue is recomputed from line items** in `fct_daily_revenue`, never trusted from the source system's stored order total — the stored total is carried alongside so drift stays visible.
- **`mart_data_quality`** runs reconciliation-style checks over the staged data (orders with no line items, totals that disagree with line items, non-positive quantities, customers who never ordered) and reports a failed-record count per check — the kind of table a data team alerts on.
- **Tests are layered**: keys and relationships in staging, segment values and non-null measures in the marts.

## Real run output

Raw data generated (fixed seed 42):

```
raw_customers: 600 rows
raw_products: 48 rows
raw_orders: 5000 rows
raw_order_items: 12563 rows
```

`dbt build` (dbt-core 1.12.6, dbt-duckdb 1.11.1):

```
Finished running 3 table models, 31 data tests, 5 view models in 1.97 seconds.
Done. PASS=39 WARN=0 ERROR=0 SKIP=0 TOTAL=39
```

What the marts found:

| Result | Value |
|---|---|
| Completed orders in `fct_daily_revenue` | 3,304 orders over 90 days (360 day × channel rows) |
| Recomputed revenue | $158,019.67 (drive-thru $39,992.61 · delivery app $39,408.42 · dine-in $39,328.67 · takeaway $39,289.97) |
| Customer segments in `dim_customers` | 441 occasional · 124 one-time · 33 regular · 2 never ordered (completed) |
| DQ check: orders whose stored total ≠ line items | **19 orders flagged** |
| DQ check: orders with no line items | **12 orders flagged** |
| DQ checks passing clean | non-positive quantities, refunded/cancelled revenue lines, customers with no orders |

The 19 and 12 are exactly the defects the generator plants — the mart catches all of them, and the 31 schema tests still pass because the defects are value-level problems, not structural ones. That distinction (tests guard structure, reconciliation marts guard values) is the point of the demo.

## Run it

```bash
pip install -r requirements.txt
python generate_raw_data.py
cd dbt_project
dbt build --profiles-dir .
```

The warehouse file defaults to `dbt_project/warehouse.duckdb`; set `WAREHOUSE_PATH=/path/to/warehouse.duckdb` to put it somewhere else (both the generator and `profiles.yml` honour the same variable).

## Tech stack

dbt Core · dbt-duckdb · DuckDB · Python 3.10+ (data generator)

## What it demonstrates

- Layered dbt modelling (sources → staging → intermediate → marts) with documented schemas
- Generic dbt tests: `unique`, `not_null`, `accepted_values`, `relationships`
- Reconciliation-style data-quality marts, not just schema tests
- Revenue recomputed from atomic line items rather than trusted from source totals
- Fully reproducible analytics engineering: fixed-seed synthetic data, one `dbt build`
