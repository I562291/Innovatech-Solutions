import mysql.connector
from dotenv import load_dotenv

def get_connection():
    return mysql.connector.connect(
        host=os.getenv("DB_HOST"),          
        user=os.getenv("DB_USER"),         
        password=os.getenv("DB_PASSWORD"), 
        database=os.getenv("DB_NAME")       
    )

def create_ticket(buyer_name):
    connection = get_connection()
    cursor = connection.cursor()
    cursor.execute(
        "CREATE TABLE IF NOT EXISTS tickets (id INT AUTO_INCREMENT PRIMARY KEY, buyer_name VARCHAR(255))"
    )
    cursor.execute(
        "INSERT INTO tickets (buyer_name) VALUES (%s)",
        (buyer_name,)
    )

    connection.commit()
    cursor.close()
    connection.close()