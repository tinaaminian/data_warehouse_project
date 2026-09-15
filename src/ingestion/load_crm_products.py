from pathlib import Path
from uuid import uuid4

from src.database import get_connection

SOURCE_FILE = Path("dataset/source_crm/prd_info.csv")

def load_crm_products():
    batch_id = uuid4()

    if not SOURCE_FILE.exists():
        raise FileNotFoundError(f"file {SOURCE_FILE} not found")


    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                create temp table temp_crm_prd_info(
                    prd_id text,
                    prd_key text,
                    prd_nm text,
                    prd_cost text,
                    prd_line text,
                    prd_start_dt text,
                    prd_end_dt text
                ) on commit drop;
            """)
            with SOURCE_FILE.open('r', encoding='utf-8') as f:
                with cur.copy("""
                    copy temp_crm_prd_info(prd_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt)
                    from stdin
                    with (format csv, header true)
                """) as copy:
                    while data := f.read(8192):
                        copy.write(data)

            cur.execute("""
                select count(*) from temp_crm_prd_info;
            """)
            rows_loaded = cur.fetchone()[0]
            

            cur.execute("""
                insert into bronze.crm_prd_info(prd_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt, source_file, batch_id)
                select prd_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt, %s, %s from temp_crm_prd_info;
            """, (SOURCE_FILE.name, batch_id))

            cur.execute("""
                select count(*) from bronze.crm_prd_info where batch_id = %s;
            """, (batch_id,))

            bronze_rows = cur.fetchone()[0]

            if bronze_rows != rows_loaded:
                raise RuntimeError(
                    f"Row-count mismatch: "
                    f"temp={rows_loaded}, bronze={bronze_rows}"
                )


if __name__ == "__main__":
    load_crm_products()