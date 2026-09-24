
from src.transformation.load_silver_customers import load_silver_customers
from src.transformation.load_silver_products import load_products
from src.database import get_connection
from uuid import uuid4

PIPELINE_NAME = 'silver'

def run_silver():

    print("Starting Silver Pipeline ....")
    pipeline_id = uuid4()

    with get_connection() as conn:
            with conn.cursor() as cur:
              
                cur.execute("""
                    insert into audit.pipeline_runs(
                    run_id,
                    pipeline_name,
                    status
                    )
                    values (%s,%s, 'STARTED')
                """,(pipeline_id,PIPELINE_NAME))


    try:
        print("Loading customers .... ")
        load_silver_customers()

        print("Loading products...")
        load_products()

    except Exception as e:
        print(f"Silver pipeline failed {e}")

        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    update audit.pipeline_runs 
                    set completed_at = now(),
                     status='FAILED',
                      error_message = %s
                    where run_id = %s
                """,(str(e),pipeline_id))
        raise
    
    else:
        print("Silver pipeline completed successfully")
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    update audit.pipeline_runs 
                    set completed_at = now(), status='SUCCESS'
                    where run_id = %s
                """,(pipeline_id,))



if __name__ == "__main__":
    run_silver()
