from pathlib import Path
from uuid import uuid4
from src.database import get_connection

SOURCE_FILE = Path("dataset/source_crm/sales_details.csv")

def load_crm_sales():
    batch_id = uuid4()

    if not SOURCE_FILE.exists():
        raise FileNotFoundError(f" source file {SOURCE_FILE} not found")
    
    with get_connection() as conn:

        with conn.cursor() as cur:
            cur.execute("""
                create temp table temp_crm_sales_details(
                    sls_ord_num TEXT,
                    sls_prd_key TEXT,
                    sls_cust_id TEXT,
                    sls_order_dt TEXT,
                    sls_ship_dt TEXT,
                    sls_due_dt TEXT,
                    sls_sales TEXT,
                    sls_quantity TEXT,
                    sls_price TEXT
                )
            """)

            with SOURCE_FILE.open('r', encoding='utf-8') as f:
                with cur.copy("""
                    copy temp_crm_sales_details(sls_ord_num,
                    sls_prd_key,
                    sls_cust_id,
                    sls_order_dt,
                    sls_ship_dt,
                    sls_due_dt,
                    sls_sales,
                    sls_quantity,
                    sls_price)
                    from STDIN 
                    with (format csv, header true)
                """) as copy:
                    while data := f.read(8192):
                        copy.write(data)

            cur.execute("""
                select count(*)
                from temp_crm_sales_details
            """)
            count_temp_rows = cur.fetchone()[0]

            cur.execute("""
            
                insert into bronze.crm_sales_details(
                sls_ord_num,sls_prd_key,sls_cust_id,sls_order_dt,sls_ship_dt,sls_due_dt,sls_sales,sls_quantity,sls_price,source_file,batch_id
                )
                select sls_ord_num,sls_prd_key,sls_cust_id,sls_order_dt,sls_ship_dt,sls_due_dt,sls_sales,sls_quantity,sls_price,%s,%s
                from temp_crm_sales_details
            
            """, (SOURCE_FILE.name, batch_id))

            cur.execute(
                """
                    select count(*)
                    from bronze.crm_sales_details
                    where batch_id = %s
                """, (batch_id,)
            )
            count_bronze_sales_rows = cur.fetchone()[0]

            if count_bronze_sales_rows != count_temp_rows:
                raise RuntimeError('matching issue occured')

            print(f"number of rows in temp table is : {count_temp_rows}")



if __name__ == '__main__':
    load_crm_sales()

