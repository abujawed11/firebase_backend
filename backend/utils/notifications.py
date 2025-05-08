import firebase_admin
from firebase_admin import credentials, messaging
from config.config import Config

# # Initialize Firebase Admin SDK
# cred = credentials.Certificate(Config.FIREBASE_CREDENTIALS_PATH)
# firebase_admin.initialize_app(cred)

# def send_notification(token, title, body, data=None):
#     try:
#         message = messaging.Message(
#             notification=messaging.Notification(
#                 title=title,
#                 body=body,
#             ),
#             token=token,
#             data=data
#         )
#         response = messaging.send(message)
#         return True, response
#     except Exception as e:
#         return False, str(e) 


cred = credentials.Certificate(Config.FIREBASE_CREDENTIALS_PATH)
firebase_admin.initialize_app(cred)
def send_notification(token, title, body, data=None):
    """Send FCM notification to a specific token."""
    try:
        print(f"Building message for token: {token[:10]}..., title: {title}, body: {body}")
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            token=token,
            data=data
        )
        print("Sending message to Firebase")
        response = messaging.send(message)
        print(f"Notification sent successfully: {response}")
        return True, response
    except Exception as e:
        print(f"Error sending notification: {e}")
        return False, str(e)
