import os
from dotenv import load_dotenv
import pymysql

load_dotenv()

try:
    connection = pymysql.connect(
        host=os.getenv("DB_HOST"),
        port=int(os.getenv("DB_PORT")),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        database=os.getenv("DB_NAME")
    )

    print("MySQL connection successful!")

    with connection.cursor() as cursor:
        cursor.execute("SELECT DATABASE()")
        print("Database:", cursor.fetchone())

    connection.close()

except Exception as e:
    print("Connection failed:", repr(e))