
import os

import firebase_admin
from firebase_admin import credentials
from dotenv import load_dotenv


# Load environment variables from the backend .env file
load_dotenv()


def initialize_firebase():
    """
    Initialize Firebase Admin SDK.

    Reuses the existing default Firebase app if
    it has already been initialized.
    """

    # Check whether Firebase is already initialized
    try:
        return firebase_admin.get_app()

    except ValueError:
        pass

    # Read service account path from environment
    credentials_path = os.getenv("FIREBASE_CREDENTIALS_PATH")

    if not credentials_path:
        raise RuntimeError(
            "FIREBASE_CREDENTIALS_PATH is not configured."
        )

    if not os.path.isfile(credentials_path):
        raise FileNotFoundError(
            f"Firebase credentials file not found: {credentials_path}"
        )

    # Load Firebase service account credentials
    firebase_credentials = credentials.Certificate(
        credentials_path
    )

    # Initialize Firebase Admin SDK
    firebase_app = firebase_admin.initialize_app(
        firebase_credentials
    )

    return firebase_app
