from src.ingestion.load_crm_customers import load_crm_customers
from src.ingestion.load_crm_products import load_crm_products
from src.ingestion.load_crm_sales import load_crm_sales_details
from src.ingestion.load_erp_customers import load_erp_customers
from src.ingestion.load_erp_loc import load_erp_loc
from src.ingestion.load_erp_px import load_erp_px


def run_bronze():
    
    print("Starting Bronze ingestion...")

    load_crm_customers()
    load_crm_products()
    load_crm_sales_details()

    load_erp_customers()
    load_erp_loc()
    load_erp_px()

    print("Bronze ingestion completed successfully.")



if __name__ == "__main__":
    run_bronze()
