from pathlib import Path
from uuid import uuid4

from src.database import get_connection

SOURCE_FILE = Path("dataset/source_crm/cust_info.csv")

def load_crm_customers():
    batch_id = str(uuid4())

    if not SOURCE_FILE.exists():
        raise FileNotFoundError(f"Source file {SOURCE_FILE} not found")

    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                create temp table if not exists temp_crm_cust_info(
                    cst_id text,
                    cst_key text,
                    cst_firstname text,
                    cst_lastname text,
                    cst_marital_status text,
                    cst_gndr text,
                    cst_create_date text
                ) on commit drop;
                """
            )

            with SOURCE_FILE.open('r', encoding='utf-8') as f:
                with cur.copy("""
                    copy temp_crm_cust_info(cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date)
                    from stdin
                    with (format csv, header true)
                """) as copy:
                    while data := f.read(8192):
                        copy.write(data)

            cur.execute("""
                select count(*) from temp_crm_cust_info;
            """) 

            rows_loaded = cur.fetchone()[0] 

            cur.execute("""
                insert into bronze.crm_cust_info(
                    cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date,
                    source_file, batch_id
                )
                select cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date,
                %s, %s from temp_crm_cust_info;
            """, (SOURCE_FILE.name, batch_id))

            cur.execute("""
                select count(*)
                from bronze.crm_cust_info
                where batch_id = %s;            
            """, (batch_id,))

            bronze_rows = cur.fetchone()[0]

            if bronze_rows != rows_loaded:
                raise RuntimeError(
                    f"Row-count mismatch: "
                    f"temp={rows_loaded}, bronze={bronze_rows}"
                )



if __name__ == "__main__":
    load_crm_customers()