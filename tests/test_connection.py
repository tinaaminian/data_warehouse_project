from src.database import get_connection

with get_connection() as conn:
    with conn.cursor() as cursor:
        cursor.execute("SELECT 1")
        result = cursor.fetchone()
        print(result)