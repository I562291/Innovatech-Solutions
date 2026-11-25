import mysql.connector, boto3

def get_connection(): # we gaan hier gebruik maken van aws ssm parameter store via boto3 om db cred te halen
    ssm = boto3.client('ssm', region_name='eu-central-1')
    db_host = ssm.get_parameter(Name='/innovatech/db/host', WithDecryption=True)['Parameter']['Value']
    db_user = ssm.get_parameter(Name='/innovatech/db/user', WithDecryption=True)['Parameter']['Value']
    db_password = ssm.get_parameter(Name='/innovatech/db/password', WithDecryption=True)['Parameter']['Value']
    db_name = ssm.get_parameter(Name='/innovatech/db/name', WithDecryption=True)['Parameter']['Value']

    connection = mysql.connector.connect( # we gebruiken de opgehaalde db cred uit de parameter store om een connectie te maken met de mysql db
        host=db_host,
        user=db_user,
        password=db_password,
        database=db_name
    )
    return connection

def onboard_employee(user_name, role, IP_address):
    connection = get_connection()
    cursor = connection.cursor()
    cursor.execute(
        "CREATE TABLE IF NOT EXISTS employees (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(255), role VARCHAR(255), ip_address VARCHAR(255))"
    )
    cursor.execute(
        "INSERT INTO employees (name, role, ip_address) VALUES (%s, %s, %s)",
        (user_name, role, IP_address)
    )
    connection.commit()  # opslaan
    cursor.close()
    connection.close()

def offboard_employee(user_name):
    connection = get_connection()
    cursor = connection.cursor()
    cursor.execute(
        "DELETE FROM employees WHERE name = %s",
        (user_name,)
    )
    connection.commit()  # opslaan
    cursor.close()
    connection.close()