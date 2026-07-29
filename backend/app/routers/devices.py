from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import get_current_user
from ..models import DeviceInfo, User
from ..schemas import DeviceRequest
from ..serializers import device_to_client

router = APIRouter(prefix="/api/devices", tags=["devices"])


@router.post("")
def register_device(payload: DeviceRequest, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if payload.platform not in {"ios", "android", "web"}:
        raise HTTPException(status_code=400, detail="Unsupported platform")
    device = db.scalar(
        select(DeviceInfo).where(DeviceInfo.user_id == current_user.id, DeviceInfo.device_id == payload.deviceId)
    )
    if not device:
        device = DeviceInfo(user_id=current_user.id, device_id=payload.deviceId, platform=payload.platform)
    device.push_token = payload.pushToken
    device.platform = payload.platform
    device.updated_at = datetime.now(timezone.utc)
    db.add(device)
    db.commit()
    db.refresh(device)
    return {"success": True, "device": device_to_client(device)}
