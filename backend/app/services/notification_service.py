
import logging

from firebase_admin import messaging

from app.models import User, FCMDeviceToken
from app.services.firebase_service import initialize_firebase


logger = logging.getLogger(__name__)


def send_announcement_notification(
    db,
    announcement_id: int,
    title: str,
    message: str
):
    """
    Send announcement notifications to active STUDENT
    and STAFF devices using Firebase Installation IDs (FIDs).

    Firebase supports a maximum of 500 FIDs per multicast message.
    """

    try:
        firebase_app = initialize_firebase()
    except Exception:
        logger.exception("Firebase initialization failed.")
        return {
            "success": False,
            "total_devices": 0,
            "sent": 0,
            "failed": 0
        }

    # Retrieve active FIDs belonging to students and staff
    device_records = (
        db.query(FCMDeviceToken)
        .join(User, FCMDeviceToken.user_id == User.user_id)
        .filter(
            FCMDeviceToken.is_active == True,
            User.role.in_(["STUDENT", "STAFF"])
        )
        .all()
    )

    if not device_records:
        logger.info("No active student/staff FIDs found.")
        return {
            "success": True,
            "total_devices": 0,
            "sent": 0,
            "failed": 0
        }

    sent_count = 0
    failed_count = 0

    # Process FIDs in batches of 500
    for start in range(0, len(device_records), 500):
        batch = device_records[start:start + 500]

        fids = [record.token for record in batch]

        notification = messaging.Notification(
            title=title,
            body=message
        )

        multicast_message = messaging.MulticastMessage(
            notification=notification,
            data={
                "type": "ANNOUNCEMENT",
                "announcement_id": str(announcement_id)
            },
            fids=fids
        )

        try:
            response = messaging.send_each_for_multicast(
                multicast_message,
                app=firebase_app
            )

            for record, result in zip(batch, response.responses):

                if result.success:
                    sent_count += 1

                else:
                    failed_count += 1

                    logger.warning(
                        "FCM notification failed for device record ID %s: %s",
                        record.token_id,
                        result.exception
                    )

        except Exception:
            failed_count += len(batch)

            logger.exception(
                "Failed to send announcement notification batch."
            )

    return {
        "success": failed_count == 0,
        "total_devices": len(device_records),
        "sent": sent_count,
        "failed": failed_count
    }
