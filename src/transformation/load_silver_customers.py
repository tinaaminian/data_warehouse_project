# transformation from bronze to silver
from src.database import get_connection
from pathlib import Path 

SQL_FILE = (
    Path(__file__).resolve().parents[2] / "sql" / "silver" / "transformations" / "load_customers.sql"
)
VALIDATION_FILE = (
    Path(__file__).resolve().parents[2] / "sql" / "silver" / "validation" / "validation.sql"
)

def load_silver_customers():

    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                truncate table silver.customers
            """)

            # Bronze -> Silver transfer through insertion
            sql = SQL_FILE.read_text()
            cur.execute(sql)

            # Reconcilation 
            validation = VALIDATION_FILE.read_text()
            cur.execute(validation)
            
            (validate_crm_count, 
            integrated_count, 
            silver_count,
            missing_from_silver_count) = cur.fetchone()

            print(f"Valid CRM customers: {validate_crm_count}")
            print(f"Integrated customers: {integrated_count}")
            print(f"Silver customers: {silver_count}")
            print(f"Silver customers: {missing_from_silver_count}")

            if validate_crm_count != integrated_count:
                raise RuntimeError(
                    "Customer integration reconciliation failed: "
                    f"valid_crm={validate_crm_count}, "
                    f"integrated={integrated_count}"
                )

            # Check that the integrated dataset reached Silver.
            if integrated_count != silver_count:
                raise RuntimeError(
                    "Silver customer load reconciliation failed: "
                    f"integrated={integrated_count}, "
                    f"silver={silver_count}"
                )
            # Check missing from silver
            if missing_from_silver_count !=0:
                raise RuntimeError(f"Customer key reconciliation failed: {missing_from_silver_count} valid CRM customers are missing from Silver")

           
    print(
         f"Silver customer load completed successfully: "
         f"{silver_count} customers loaded."
    )
    






if __name__ == "__main__":
    load_silver_customers()