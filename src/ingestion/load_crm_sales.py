from pathlib import Path
from uuid import uuid4
from src.database import get_connection
from src.ingestion.ingestion_utils import (calculate_file_hash,
already_ingested,log_started,log_failed)


SOURCE_FILE = Path("dataset/source_crm/sales_details.csv")
SOURCE_SYSTEM = "CRM"


def load_bronze(batch_id):
    
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

            cur.execute("""
                UPDATE bronze.ingestion_log
                SET completed_at = NOW(),
                status = 'SUCCESS',
                rows_loaded = %s,
                error_message = NULL
                WHERE batch_id = %s 
            """,(count_bronze_sales_rows,batch_id)
            )
            return count_bronze_sales_rows

#===================================
# Main ingestion workflow
#====================================

def load_crm_sales_details():

    # Making sure file exists
      if not SOURCE_FILE.exists():
          raise FileNotFoundError(f"Source file {SOURCE_FILE} not found")

    # Calculating hash 
      file_hash = calculate_file_hash(SOURCE_FILE)

    # Idenotency Check
      if already_ingested(SOURCE_SYSTEM,file_hash):
        print(f"{SOURCE_FILE.name} has already been successfully ingested. Skipping...")
        return

    # Creating unique ID for this ingestion attempt
      batch_id = uuid4()

      # Recird STARTED and commit it independently
      log_started(batch_id,SOURCE_SYSTEM,SOURCE_FILE.name,file_hash)

      try:
        rows_loaded = load_bronze(batch_id)

      except Exception as e:
        log_failed(batch_id,e)
        raise

      else:
        print(f"successfully loaded into table")


          



if __name__ == '__main__':
    load_crm_sales_details()

