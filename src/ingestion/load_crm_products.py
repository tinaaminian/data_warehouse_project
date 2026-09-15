from pathlib import Path
from uuid import uuid4
from src.database import get_connection
from src.ingestion.ingestion_utils import (calculate_file_hash,
already_ingested,log_started,log_failed)

SOURCE_FILE = Path("dataset/source_crm/prd_info.csv")
SOURCE_SYSTEM = "CRM"


def load_bronze(batch_id):

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
            cur.execute("""
                UPDATE bronze.ingestion_log
                SET completed_at = NOW(),
                status = 'SUCCESS',
                rows_loaded = %s,
                error_message = NULL
                WHERE batch_id = %s 
            """,(bronze_rows,batch_id)
            )
            return bronze_rows

#===================================
# Main ingestion workflow
#====================================
def load_crm_products():
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




if __name__ == "__main__":
    load_crm_products()