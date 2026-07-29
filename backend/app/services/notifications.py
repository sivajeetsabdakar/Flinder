from datetime import datetime, timezone
from typing import Any
import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..config import get_settings
from ..models import DeviceInfo, Notification, NotificationDelivery


def create_notification(
    db: Session,
    user_id: uuid.UUID,
    type_: str,
    title: str,
    body: str,
    data: dict[str, Any] | None = None,
    send_push: bool = True,
) -> Notification:
    notification = Notification(user_id=user_id, type=type_, title=title, body=body, data=data or {})
    db.add(notification)
    db.flush()
    if send_push:
        queue_push_deliveries(db, notification)
    return notification


def queue_push_deliveries(db: Session, notification: Notification) -> None:
    devices = db.scalars(
        select(DeviceInfo).where(DeviceInfo.user_id == notification.user_id, DeviceInfo.push_token.is_not(None))
    ).all()
    if not devices:
        db.add(NotificationDelivery(notification_id=notification.id, status="skipped", error="No registered push devices"))
        return

    settings = get_settings()
    if not settings.firebase_credentials_path:
        for device in devices:
            db.add(
                NotificationDelivery(
                    notification_id=notification.id,
                    device_info_id=device.id,
                    status="skipped",
                    error="Firebase credentials are not configured",
                )
            )
        return

    try:
        import firebase_admin
        from firebase_admin import credentials, messaging

        if not firebase_admin._apps:
            firebase_admin.initialize_app(credentials.Certificate(settings.firebase_credentials_path))

        for device in devices:
            delivery = NotificationDelivery(notification_id=notification.id, device_info_id=device.id)
            try:
                message_id = messaging.send(
                    messaging.Message(
                        token=device.push_token,
                        notification=messaging.Notification(title=notification.title, body=notification.body),
                        data={key: str(value) for key, value in (notification.data or {}).items()},
                    )
                )
                delivery.status = "sent"
                delivery.provider_message_id = message_id
                delivery.sent_at = datetime.now(timezone.utc)
            except Exception as exc:
                delivery.status = "failed"
                delivery.error = str(exc)
            db.add(delivery)
    except Exception as exc:
        for device in devices:
            db.add(
                NotificationDelivery(
                    notification_id=notification.id,
                    device_info_id=device.id,
                    status="failed",
                    error=str(exc),
                )
            )
