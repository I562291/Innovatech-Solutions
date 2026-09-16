import mysql.connector

def get_connection():
    return mysql.connector.connect(
        host="DATABASE_HOST",
        user="DATABASE_USER",
        password="DATABASE_PASSWORD",
        database="innovatech"
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