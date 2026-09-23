from pathlib import Path 
from src.database import get_connection


SQL_FILE = (
    Path(__file__).resolve().parents[2] / "sql" / "silver" / "transformations" / "load_products.sql"
)

def load_products():

    sql = SQL_FILE.read_text(encoding="utf-8")

    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                TRUNCATE TABLE silver.products
            """)
            cur.execute(sql)

            cur.execute("""
            
                select count(*)
                from silver.products
            """)
            result = cur.fetchone()[0]
            print(f"number of loaded rows:{result}")
    print('success')





if __name__ == "__main__":
    load_products()