from pathlib import Path
from uuid import uuid4
from src.ingestion.ingestion_utils import already_ingested, calculate_file_hash,log_started,log_failed
from src.database import get_connection

SOURCE_FILE = Path('dataset/source_erp/CUST_AZ12.CSV')
SOURCE_SYSTEM = "ERP"

def load_bronze(batch_id):
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
            
                create temp table temp_erp_customers(
                    cid TEXT,
                    bdate TEXT,
                    gen TEXT
                ) ON COMMIT DROP
            """)
            with SOURCE_FILE.open('r', encoding="UTF-8") as f:
                with cur.copy("""
                    copy temp_erp_customers(cid,bdate,gen)
                    from stdin
                    with (format csv, header true)
                    """) as copy:
                    while data := f.read(8192):
                        copy.write(data)
            cur.execute(
                """
                    select count(*)
                    from temp_erp_customers
                """
            )
            temp_rows = cur.fetchone()[0]

            cur.execute("""
            
                INSERT INTO bronze.erp_cust_az12 (cid, bdate,gen,source_file, batch_id)
                select cid, bdate,gen,%s,%s
                from temp_erp_customers
            """,(SOURCE_FILE.name,batch_id))

            # Validating this specific batch:
            cur.execute("""
            
                select count(*)
                from bronze.erp_cust_az12
                where batch_id = %s
            """,(batch_id,))

            bronze_erp_cust_rows = cur.fetchone()[0]

            if bronze_erp_cust_rows != temp_rows:
                raise RuntimeError(f"row count mismatch temp: {temp_rows} and bronze:{bronze_erp_cust_rows}")

            # If there is no Error, then we can update log table
            cur.execute("""
                UPDATE bronze.ingestion_log
                SET status = 'SUCCESS',
                completed_at = NOW(),
                rows_loaded = %s,
                error_message = NULL
                where batch_id = %s
            """,(bronze_erp_cust_rows,batch_id))

            return bronze_erp_cust_rows

def load_erp_customers():

    # Check file exists or not
    if not SOURCE_FILE.exists():
        raise FileNotFoundError(f"{SOURCE_FILE} cannot be found")


    # Create file content's hash
    hash_file = calculate_file_hash(SOURCE_FILE)

    # Check whether this file has been ingested in database table or not
    result = already_ingested(SOURCE_SYSTEM,hash_file)

    if result:
        print(f"this file has been ingested in database. Skipping...")
        return

    # IF not exists, then generate a unique batch_id and start loging process
    batch_id = uuid4()

    log_started(batch_id,SOURCE_SYSTEM,SOURCE_FILE.name,hash_file)

    try:
        rows_loaded = load_bronze(batch_id)

    except Exception as e:
        log_failed(batch_id, e)
        raise

    else:
        print(f"source file has been loaded successfully {rows_loaded}")




if __name__ == "__main__":
    load_erp_customers()