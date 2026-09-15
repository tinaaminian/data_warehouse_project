from pathlib import Path
from uuid import uuid4
import hashlib
from src.database import get_connection

#===================================
# getting source file
#====================================

SOURCE_FILE = Path("dataset/source_crm/cust_info.csv")
SOURCE_SYSTEM = "CRM"

#===================================
# Calculating SHA-256 hash for file content to prevent duplicate loading
#====================================

def calculate_file_hash(filepath):
    sha256 = hashlib.sha256()

    with filepath.open('rb') as f:
        while chunk := f.read(8192):
            sha256.update(chunk)
    return sha256.hexdigest()


#===================================
# Checking whether this exact file was already loaded successfully or not
#====================================

def already_ingested(file_hash):
    with get_connection as conn:
        with conn.cursor() as cur:
            cur.execute("""
                select 1
                from bronze.ingestion_log
                where source_system = %s AND
                file_hash = %s AND
                status = 'SUCCESS'
            """, (SOURCE_SYSTEM,file_hash))

            return cur.fetchone()

#===================================
# Log STARTED
#====================================
def log_started(batch_id, file_hash):
    with get_connection as conn:
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO bronze.ingestion_log(
                    batch_id,
                    source_system,
                    source_file,
                    file_hash,
                    status
                )
                VALUES(%s,%s,%s,%s,'STARTED')
            """,(batch_id,SOURCE_SYSTEM,SOURCE_FILE.name,file_hash))


#===================================
# Log SUCCESS
#====================================
def log_success(batch_id, rows_loaded):
    with get_connection as conn:
        with conn.cursor() as cur:
            cur.execute("""
                UPDATE bronze.ingestion_log
                SET completed_at = NOW() AND
                status = 'SUCCESS' AND 
                rows_loaded = %s AND
                error_message = NULL
                WHERE batch_id = %s 
            """,(rows_loaded,batch_id)
            )


#===================================
# Log FAILED
#====================================

def log_failed(batch_id,error_message):
    with get_connection as conn:
        with conn.cursor() as cur:
            cur.execute("""
                UPDATE bronze.ingestion_log
                SET error_message = %s AND
                status = 'FAILED'
                WHERE batch_id = %s
            """,(str(error_message),batch_id)
            )


#===================================
# loading source content to database corresponding table using log table
#====================================

def load_bronze(batch_id):
   
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
                    """)
            # Bulk load from source file to temp table
            with SOURCE_FILE.open('r', encoding='utf-8') as f:
                    with cur.copy("""
                        copy temp_crm_cust_info(cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date)
                        from stdin
                        with (format csv, header true)
                    """) as copy:
                        while data := f.read(8192):
                            copy.write(data)

            # Counting temp table rows
            cur.execute("""
                    select count(*) from temp_crm_cust_info;
                """) 

            rows_loaded = cur.fetchone()[0] 


            # Moving data from temp table to Bronze corresponding table + Metadata
            cur.execute("""
                    insert into bronze.crm_cust_info(
                        cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date,
                        source_file, batch_id
                    )
                    select cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date,
                    %s, %s from temp_crm_cust_info;
                """, (SOURCE_FILE.name, batch_id))

            # Validating this specific batch
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
            return rows_loaded
   
#===================================
# Main ingestion workflow
#====================================

def load_crm_customers():

    # Making sure file exists
      if not SOURCE_FILE.exists():
          raise FileNotFoundError(f"Source file {SOURCE_FILE} not found")

    # Calculating hash 
      file_hash = calculate_file_hash(SOURCE_FILE)

    # Idenotency Check
      if already_ingested(file_hash):
        print(f"{SOURCE_FILE.name} has already been successfully ingested. Skipping...")

    # Creating unique ID for this ingestion attempt
      batch_id = uuid4()

      # Recird STARTED and commit it independently
      log_started(batch_id, file_hash)

      try:
        rows_loaded = load_bronze(batch_id)

      except Exception as e:
        log_failed(batch_id,e)
        raise

      else:
        log_success(batch_id, rows_loaded)
        print(f"successfully loaded into table")




if __name__ == "__main__":
 load_crm_customers()