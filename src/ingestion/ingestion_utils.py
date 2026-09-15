import hashlib
from src.database import get_connection
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

def already_ingested(source_system, file_hash):
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                select 1
                from bronze.ingestion_log
                where source_system = %s AND
                file_hash = %s AND
                status = 'SUCCESS'
            """, (source_system,file_hash))

            return cur.fetchone()


#===================================
# Log STARTED
#====================================
def log_started(batch_id,source_system,source_name,file_hash):
    with get_connection() as conn:
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
            """,(batch_id,source_system,source_name,file_hash))

#===================================
# Log FAILED
#====================================

def log_failed(batch_id,error_message):
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                UPDATE bronze.ingestion_log
                SET error_message = %s,
                status = 'FAILED',
                completed_at = NOW()
                WHERE batch_id = %s
            """,(str(error_message),batch_id)
            )
