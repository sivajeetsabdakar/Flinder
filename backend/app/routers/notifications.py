import uuid

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import get_current_user
from ..models import Notification, User
from ..serializers import notification_to_client

router = APIRouter(prefix="/api/notifications", tags=["notifications"])


@router.get("")
def list_notifications(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    rows = db.scalars(
        select(Notification)
        .where(Notification.user_id == current_user.id)
        .order_by(Notification.created_at.desc())
        .limit(50)
    ).all()
    unread = sum(1 for row in rows if not row.is_read)
    return {"success": True, "unreadCount": unread, "notifications": [notification_to_client(row) for row in rows]}


@router.post("/{notification_id}/read")
def mark_notification_read(notification_id: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    notification = db.get(Notification, uuid.UUID(notification_id))
    if notification and notification.user_id == current_user.id:
        notification.is_read = True
        db.commit()
    return {"success": True}
