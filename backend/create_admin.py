from getpass import getpass

from app.database.connection import SessionLocal
from app.models.models import User
from app.main import hash_password


def create_admin():
    db = SessionLocal()

    try:
        name = input("Enter admin name: ").strip()
        email = input("Enter admin NITC email: ").strip().lower()
        password = getpass("Enter admin password: ")
        confirm_password = getpass("Confirm password: ")

        if not email.endswith("@nitc.ac.in"):
            print("Only NITC email addresses are allowed.")
            return

        if password != confirm_password:
            print("Passwords do not match.")
            return

        if not password:
            print("Password cannot be empty.")
            return

        existing_user = db.query(User).filter(
            User.email == email
        ).first()

        if existing_user:
            print("This email is already registered.")
            return

        admin = User(
            name=name,
            email=email,
            password_hash=hash_password(password),
            role="ADMIN"
        )

        db.add(admin)
        db.commit()

        print("ADMIN account created successfully!")

    except Exception as e:
        db.rollback()
        print("Error:", e)

    finally:
        db.close()


if __name__ == "__main__":
    create_admin()