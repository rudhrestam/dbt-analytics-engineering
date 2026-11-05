"""Generate synthetic raw restaurant/e-commerce data into a DuckDB file.

Creates schema `raw_data` with four tables (customers, products, orders,
order_items) in dbt_project/warehouse.duckdb. A handful of deliberate
data-quality issues are planted (orders whose stored total disagrees with
their line items, orders with no line items) so the dbt data-quality mart
has something real to catch. Fixed seed = reproducible.
"""
import random
import datetime as dt
from pathlib import Path

import duckdb

random.seed(42)
BASE = Path(__file__).resolve().parent / "dbt_project"
# Warehouse location can be overridden (e.g. to a fast local disk) via env var.
import os
DB = Path(os.environ.get("WAREHOUSE_PATH", BASE / "warehouse.duckdb"))
if DB.exists():
    DB.unlink()

con = duckdb.connect(str(DB))
con.execute("CREATE SCHEMA raw_data")
con.execute("""CREATE TABLE raw_data.raw_products(
    product_id INTEGER, product_name VARCHAR, category VARCHAR, unit_price DOUBLE)""")
con.execute("""CREATE TABLE raw_data.raw_customers(
    customer_id INTEGER, full_name VARCHAR, email VARCHAR,
    signup_date DATE, home_store VARCHAR)""")
con.execute("""CREATE TABLE raw_data.raw_orders(
    order_id INTEGER, customer_id INTEGER, order_ts TIMESTAMP,
    channel VARCHAR, status VARCHAR, stored_total DOUBLE)""")
con.execute("""CREATE TABLE raw_data.raw_order_items(
    item_id INTEGER, order_id INTEGER, product_id INTEGER,
    quantity INTEGER, line_total DOUBLE)""")

CATEGORIES = ["burgers", "chicken", "sides", "drinks", "desserts", "salads"]
products = []
for pid in range(1, 49):
    cat = CATEGORIES[pid % len(CATEGORIES)]
    products.append((pid, f"{cat[:-1].title()} Item {pid:02d}", cat,
                     round(random.uniform(2.5, 18.0), 2)))
con.executemany("INSERT INTO raw_data.raw_products VALUES (?,?,?,?)", products)

first = ["Ava", "Liam", "Maya", "Noah", "Zoe", "Eli", "Ivy", "Omar", "Nina", "Raj",
         "Sara", "Tom", "Lena", "Karl", "Ana", "Ben", "Mia", "Jay", "Kim", "Leo"]
last = ["Shah", "Patel", "Garcia", "Kim", "Novak", "Ali", "Rossi", "Berg",
        "Costa", "Dube", "Frost", "Hale", "Ivers", "Jones", "Kaur", "Lopez"]
stores = ["Downtown", "Airport", "Suburb North", "Suburb South", "Campus"]
customers = []
start = dt.date(2025, 1, 1)
for cid in range(1, 601):
    name = f"{random.choice(first)} {random.choice(last)}"
    customers.append((cid, name,
                      f"{name.lower().replace(' ', '.')}{cid}@example.com",
                      start + dt.timedelta(days=random.randint(0, 300)),
                      random.choice(stores)))
con.executemany("INSERT INTO raw_data.raw_customers VALUES (?,?,?,?,?)", customers)

CHANNELS = ["dine_in", "takeaway", "delivery_app", "drive_thru"]
STATUSES = ["completed", "completed", "completed", "completed", "refunded", "cancelled"]
price = {p[0]: p[3] for p in products}
orders, items = [], []
item_id = 0
day0 = dt.datetime(2025, 9, 1, 8, 0, 0)
for oid in range(1, 5001):
    ts = day0 + dt.timedelta(days=random.randint(0, 89),
                             hours=random.randint(0, 13),
                             minutes=random.randint(0, 59))
    status = random.choice(STATUSES)
    n_items = random.randint(1, 4)
    total = 0.0
    if oid % 401 == 0:
        n_items = 0  # planted: order with no line items
    for _ in range(n_items):
        item_id += 1
        pid = random.randint(1, 48)
        qty = random.randint(1, 3)
        line = round(price[pid] * qty, 2)
        total += line
        items.append((item_id, oid, pid, qty, line))
    stored = round(total, 2)
    if oid % 263 == 0 and n_items > 0:
        stored = round(total + random.choice([1.5, -2.0, 5.25]), 2)  # planted mismatch
    orders.append((oid, random.randint(1, 600), ts,
                   random.choice(CHANNELS), status, stored))
con.executemany("INSERT INTO raw_data.raw_orders VALUES (?,?,?,?,?,?)", orders)
con.executemany("INSERT INTO raw_data.raw_order_items VALUES (?,?,?,?,?)", items)

for t in ["raw_customers", "raw_products", "raw_orders", "raw_order_items"]:
    n = con.execute(f"SELECT COUNT(*) FROM raw_data.{t}").fetchone()[0]
    print(f"{t}: {n} rows")
con.close()
print(f"Wrote {DB}")
