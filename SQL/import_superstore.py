
import csv
import mysql.connector

CSV_FILE = r"C:\Users\yerrm\OneDrive\Documents\Desktop\retail-sales-customer-analysis\superstore_clean_data.csv"

conn = mysql.connector.connect(
    host="localhost",
    user="root",
    password="yerram",
    database="retail_sales_analysis"
)

cursor = conn.cursor()
cursor.execute("SELECT DATABASE(), @@hostname, @@port, CURRENT_USER()")
print("Connection details:", cursor.fetchone())

cursor.execute("SELECT COUNT(*) FROM superstore_raw_import")
print("Verified row count:", cursor.fetchone()[0])

cursor.execute("DELETE FROM superstore_raw_import")

sql = """
INSERT INTO superstore_raw_import (
    `Order ID`, `Order Date`, `Ship Date`, `Ship Mode`,
    `Customer ID`, `Customer Name`, `Segment`, `Country`,
    `City`, `State`, `Postal Code`, `Region`, `Product ID`,
    `Category`, `Sub-Category`, `Product Name`, `Sales`,
    `Quantity`, `Discount`, `Profit`, `Year`, `Month`,
    `Month_number`, `PROFIT_MARGIN`, `Profit_Status`,
    `shipping_days`
) VALUES (
    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,
    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
)
"""

with open(CSV_FILE, "r", newline="", encoding="utf-8-sig") as file:
    reader = csv.reader(file)
    next(reader)  # Skip header

    batch = []
    total = 0

    for row in reader:
        batch.append(tuple(value if value != "" else None for value in row))

        if len(batch) == 500:
            cursor.executemany(sql, batch)
            conn.commit()
            total += len(batch)
            print(f"Imported {total} rows")
            batch = []

    if batch:
        cursor.executemany(sql, batch)
        conn.commit()
        total += len(batch)

print(f"\nCSV rows processed: {total}")

cursor.execute("SELECT COUNT(*) FROM superstore_raw_import")
db_count = cursor.fetchone()[0]

print(f"Rows in MySQL: {db_count}")

cursor.close()
conn.close()
