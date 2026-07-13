import mysql.connector
import random
from datetime import datetime, timedelta
import os
from dotenv import load_dotenv

load_dotenv()

random.seed(42)

conn = mysql.connector.connect(
    host="localhost",
    user="root",             
    password=os.getenv("DB_PASSWORD"),
    database="bapcor_bi"
)
cur = conn.cursor()

cur.execute("DELETE FROM fact_orders")
cur.execute("DELETE FROM fact_inventory")
conn.commit()

#cretaing stores
REGIONS = ["Auckland", "Waikato", "Bay of Plenty", "Wellington", "Canterbury", "Otago"]
STORE_BRANDS = ["BNT", "Autolign", "Truck and Trailer Parts", "Precision Equipment", "HCB Technologies"]
CHANNELS = ["Trade", "Service", "Specialist Wholesale"]

stores = []
store_id = 1
for region in REGIONS:
    for brand in STORE_BRANDS:
        channel = random.choice(CHANNELS)
        stores.append((store_id, f"{brand} {region}", brand, region, channel))
        store_id += 1

insert_store_sql = """
    INSERT INTO dim_stores (store_id, store_name, brand, region, channel)
    VALUES (%s, %s, %s, %s, %s)
"""
cur.execute("DELETE FROM dim_stores")
cur.executemany(insert_store_sql, stores)
conn.commit()
print(f"Inserted {len(stores)} stores")

#cretaing products
CATEGORIES = ["Brakes", "Filters", "Batteries", "Lighting", "Suspension", "Engine Parts", "Electrical", "Tools"]

products = []
product_id = 1
for product_id in range(1,121):
    category = random.choice(CATEGORIES)
    product_name = f"{category} Part {product_id:03d}"
    unit_cost = round(random.uniform(5,300),2)
    unit_price = round(random.uniform(unit_cost*1.25,unit_cost*1.5),2)
    reorder_level = random.choice([10,15,20,25,30])

    products.append((product_id,product_name,category,unit_cost,unit_price,reorder_level))
    product_id += 1

insert_product_sql = """
    INSERT INTO dim_products (product_id,product_name,category,unit_cost,unit_price,reorder_level)
    VALUES (%s, %s, %s, %s, %s, %s)
"""

cur.execute("DELETE FROM dim_products")
cur.executemany(insert_product_sql, products)
conn.commit()
print(f"Inserted {len(products)} products")

#cretaing customers
POPULATION = ["Active", "Inactive", "OnHold"]

customers = []
customer_id = 1
for customer_id in range(1,301):
    channel = random.choice(CHANNELS)
    region = random.choice(REGIONS)
    account_status = random.choices(POPULATION, weights=[0.85,0.10,0.05])[0]
    customer_name = f"Customer {customer_id:04d}"
    credit_limit = round(random.uniform(1000,50000),2)
    if random.random() < 0.97:
        email = f"customer{customer_id}@example.co.nz"
    else:
        email = None
    customers.append((customer_id,customer_name,channel,region,account_status,credit_limit,email))
    customer_id += 1

insert_customer_sql = """
    INSERT INTO dim_customers (customer_id,customer_name,channel,region,account_status,credit_limit,email)
    VALUES (%s, %s, %s, %s, %s, %s, %s)
"""

cur.execute("DELETE FROM dim_customers")
cur.executemany(insert_customer_sql, customers)
conn.commit()
print(f"Inserted {len(customers)} customers")

#cretaing dates
dates = []
start = datetime(2024,7,1)

for i in range(730):
    d = start + timedelta(days=i)
    year = d.year
    month = d.month
    quarter = (month - 1)//3+1
    month_name = d.strftime("%B")
    day_of_week = d.strftime("%A")
    date_id = d.strftime("%Y-%m-%d")

    dates.append((date_id,year,month,quarter,month_name,day_of_week))

insert_date_sql = """
    INSERT INTO dim_dates (date_id,year,month,quarter,month_name,day_of_week)
    VALUES (%s, %s, %s, %s, %s, %s)
"""
cur.execute("DELETE FROM dim_dates")
cur.executemany(insert_date_sql, dates)
conn.commit()
print(f"Inserted {len(dates)} dates")

#cretaing orders
orders = []
order_id = 1
product_lookup = {p[0]: p for p in products}

for order_id in range(1,5001):
    order_date = random.choices(dates)[0][0]
    store_id = random.choices(stores)[0][0]
    # product_id = random.choices(products)[0][0]
    customer_id = random.choices(customers)[0][0]
    quantity = random.choices([1,1,1,2,3,5,10])[0]
    # unit_price = product_lookup[product_id][4]
    discount_pct = random.choices([0, 0.05, 0.10, 0.15], weights=[70,15,10,5])[0]
    # total_amount = round(quantity*unit_price*(1-discount_pct),2)

    if random.random() < 0.01:
        product_id = 9999          
        unit_price = 0
        total_amount = None        
    else:
        product_id = random.choices(products)[0][0]
        unit_price = product_lookup[product_id][4]
        total_amount = round(quantity * unit_price * (1 - discount_pct), 2)

    orders.append((order_id,order_date,store_id,product_id,customer_id,quantity,unit_price,discount_pct,total_amount))
    order_id += 1

    next_order_id = 5001

#duplicating some orders to check data duplication view
for i in range(15):
    original = random.choice(orders)
    duplicate = (next_order_id,) + original[1:] 
    orders.append(duplicate)
    next_order_id += 1

insert_order_sql = """
    INSERT INTO fact_orders (order_id,order_date,store_id,product_id,customer_id,quantity,unit_price,discount_pct,total_amount)
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
"""

# cur.execute("DELETE FROM fact_orders")
cur.executemany(insert_order_sql, orders)
conn.commit()
print(f"Inserted {len(orders)} orders")


#creating inventory snapshots
inventory = []
inventory_id = 1

store_ids = [s[0] for s in stores]
product_ids = [p[0] for p in products]

snapshot_start = datetime(2024, 7, 1) + timedelta(days=640) 

for i in range(0, 90, 7):   # step in 7-day increments across 90 days
    snapshot_date = (snapshot_start + timedelta(days=i)).strftime("%Y-%m-%d")

    sampled_stores = random.sample(store_ids, 10)
    sampled_products = random.sample(product_ids, 15)

    for store_id in sampled_stores:
        for product_id in sampled_products:
            quantity_on_hand = random.randint(0, 60)
            if quantity_on_hand < 15:
                quantity_on_order = random.randint(0, 20)
            else:
                quantity_on_order = 0

            inventory.append((inventory_id, snapshot_date, store_id, product_id, quantity_on_hand, quantity_on_order))
            inventory_id += 1

insert_inventory_sql = """
    INSERT INTO fact_inventory (inventory_id, snapshot_date, store_id, product_id, quantity_on_hand, quantity_on_order)
    VALUES (%s, %s, %s, %s, %s, %s)
"""

# cur.execute("DELETE FROM fact_inventory")
cur.executemany(insert_inventory_sql, inventory)
conn.commit()
print(f"Inserted {len(inventory)} inventory rows")