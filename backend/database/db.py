import mysql.connector
from mysql.connector import Error
from mysql.connector.pooling import MySQLConnectionPool
import bcrypt

# Global connection pool
connection_pool = None

def init_db(config):
    global connection_pool
    try:
        connection_pool = MySQLConnectionPool(
            pool_name=config['MYSQL_POOL_NAME'],
            pool_size=config['MYSQL_POOL_SIZE'],
            host=config['MYSQL_HOST'],
            user=config['MYSQL_USER'],
            password=config['MYSQL_PASSWORD'],
            database=config['MYSQL_DATABASE']
        )
        conn = connection_pool.get_connection()
        if conn.is_connected():
            print("MySQL connection pool initialized successfully")
            conn.close()
    except Error as e:
        print(f"Error initializing MySQL connection pool: {e}")
        raise

def signup_user(user_id, email, password):
    conn = None
    cursor = None
    try:
        conn = connection_pool.get_connection()
        cursor = conn.cursor()
        # Check if email already exists
        cursor.execute('SELECT user_id FROM users WHERE email = %s', (email,))
        if cursor.fetchone():
            return False, 'Email already exists'
        # Hash password
        hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
        # Insert user
        cursor.execute(
            'INSERT INTO users (user_id, email, password) VALUES (%s, %s, %s)',
            (user_id, email, hashed_password)
        )
        conn.commit()
        return True, None
    except Error as e:
        print(f"Error signing up user: {e}")
        return False, str(e)
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()

def authenticate_user(email, password):
    conn = None
    cursor = None
    try:
        conn = connection_pool.get_connection()
        cursor = conn.cursor()
        cursor.execute('SELECT user_id, password FROM users WHERE email = %s', (email,))
        result = cursor.fetchone()
        if result and bcrypt.checkpw(password.encode('utf-8'), result[1]):
            return result[0]
        return None
    except Error as e:
        print(f"Error authenticating user: {e}")
        return None
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()

def store_token_db(user_id, fcm_token):
    conn = None
    cursor = None
    try:
        conn = connection_pool.get_connection()
        cursor = conn.cursor()
        cursor.execute(
            'INSERT INTO tokens (user_id, fcm_token) VALUES (%s, %s) ON DUPLICATE KEY UPDATE fcm_token = %s',
            (user_id, fcm_token, fcm_token)
        )
        conn.commit()
    except Error as e:
        print(f"Error storing token: {e}")
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()

def get_token_db(user_id):
    conn = None
    cursor = None
    try:
        conn = connection_pool.get_connection()
        cursor = conn.cursor()
        cursor.execute('SELECT fcm_token FROM tokens WHERE user_id = %s', (user_id,))
        result = cursor.fetchone()
        return result[0] if result else None
    except Error as e:
        print(f"Error retrieving token: {e}")
        return None
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()

def save_notification_db(user_id, title, body, task_id):
    conn = None
    cursor = None
    try:
        conn = connection_pool.get_connection()
        cursor = conn.cursor()
        cursor.execute(
            'INSERT INTO notifications (user_id, title, body, task_id) VALUES (%s, %s, %s, %s)',
            (user_id, title, body, task_id)
        )
        conn.commit()
    except Error as e:
        print(f"Error saving notification: {e}")
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()

def get_notifications_db(user_id):
    conn = None
    cursor = None
    try:
        conn = connection_pool.get_connection()
        cursor = conn.cursor()
        cursor.execute(
            'SELECT id, title, body, task_id, timestamp FROM notifications WHERE user_id = %s ORDER BY timestamp DESC',
            (user_id,)
        )
        notifications = cursor.fetchall()
        return notifications
    except Error as e:
        print(f"Error retrieving notifications: {e}")
        return []
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()

def get_all_users():
    conn = None
    cursor = None
    try:
        conn = connection_pool.get_connection()
        cursor = conn.cursor()
        cursor.execute('SELECT user_id FROM users')
        users = cursor.fetchall()
        return [user[0] for user in users]
    except Error as e:
        print(f"Error retrieving notifications: {e}")
        return []
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()