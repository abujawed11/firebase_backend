from flask import Blueprint, request, jsonify
from utils.notifications import send_notification
from database.db import store_token_db, get_token_db, save_notification_db, get_notifications_db, authenticate_user, signup_user, get_all_users
import logging

api = Blueprint('api', __name__)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@api.route('/signup', methods=['POST'])
def signup():
    data = request.get_json()
    user_id = data.get('user_id')
    email = data.get('email')
    password = data.get('password')
    fcm_token = data.get('fcm_token')
    if not all([user_id, email, password, fcm_token]):
        return jsonify({'error': 'Missing data'}), 400
    success, result = signup_user(user_id, email, password)
    if success:
        store_token_db(user_id, fcm_token)
        return jsonify({'success': True, 'user_id': user_id}), 201
    return jsonify({'error': result}), 400

# @api.route('/login', methods=['POST'])
# def login():
#     data = request.get_json()
#     email = data.get('email')
#     password = data.get('password')
#     user_id = authenticate_user(email, password)
#     if user_id:
#         return jsonify({'success': True, 'user_id': user_id}), 200
#     return jsonify({'error': 'Invalid credentials'}), 401

@api.route('/login', methods=['POST'])
def login():
    try:
        data = request.get_json(force=True)

        if not data:
            return jsonify({'error': 'Missing JSON payload'}), 400

        email = data.get('email')
        password = data.get('password')

        if not email or not password:
            return jsonify({'error': 'Email and password are required'}), 400

        user_id = authenticate_user(email, password)

        if user_id:
            return jsonify({'success': True, 'user_id': user_id}), 200
        else:
            return jsonify({'error': 'Invalid credentials'}), 401

    except Exception as e:
        logger.exception("Error during login")
        return jsonify({'error': 'Internal server error'}), 500

@api.route('/store-token', methods=['POST'])
def store_token():
    data = request.get_json()
    user_id = data.get('user_id')
    fcm_token = data.get('fcm_token')
    if user_id and fcm_token:
        store_token_db(user_id, fcm_token)
        return jsonify({'success': True}), 200
    return jsonify({'error': 'Invalid data'}), 400

@api.route('/add-task', methods=['POST'])
def add_task():
    data = request.get_json()
    user_id = data.get('user_id')
    task_title = data.get('title')
    task_id = data.get('task_id')
    if not all([user_id, task_title, task_id]):
        return jsonify({'error': 'Missing data'}), 400
    token = get_token_db(user_id)
    if token:
        success, response = send_notification(
            token, 'New Task Assigned', f'Task: {task_title}', {'task_id': task_id}
        )
        if success:
            save_notification_db(user_id, 'New Task Assigned', f'Task: {task_title}', task_id)
            return jsonify({'success': True, 'message_id': response}), 200
        return jsonify({'error': response}), 500
    return jsonify({'error': 'No token found'}), 404

@api.route('/notifications/<user_id>', methods=['GET'])
def get_notifications(user_id):
    notifications = get_notifications_db(user_id)
    return jsonify({
        'success': True,
        'notifications': [
            {
                'id': n[0],
                'title': n[1],
                'body': n[2],
                'task_id': n[3],
                'timestamp': n[4].isoformat()
            } for n in notifications
        ]
    }), 200


@api.route('/users', methods=['GET'])
def get_users():
    try:
        users = get_all_users()
        return jsonify({
            'success': True,
            'users': users
        }), 200
    except Exception as e:
        print(f"Get users error: {e}")
        return jsonify({'error': 'Internal server error'}), 500