import uuid

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import get_current_user
from ..models import ChatMember, Flat, FlatApplication, User
from ..serializers import application_to_client, flat_to_client
from ..services.notifications import create_notification

router = APIRouter(prefix="/api/flats", tags=["flats"])


@router.get("")
def get_flats(
    city: str | None = None,
    minRent: int | None = None,
    maxRent: int | None = None,
    rooms: int | None = None,
    limit: int = Query(10, ge=1, le=50),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    query = select(Flat)
    count_query = select(func.count()).select_from(Flat)
    filters = [Flat.status == "active"]
    if city:
        filters.append(Flat.city.ilike(f"%{city}%"))
    if minRent is not None:
        filters.append(Flat.rent >= minRent)
    if maxRent is not None:
        filters.append(Flat.rent <= maxRent)
    if rooms is not None:
        filters.append(Flat.num_rooms == rooms)

    for condition in filters:
        query = query.where(condition)
        count_query = count_query.where(condition)

    total = db.scalar(count_query) or 0
    flats = db.scalars(query.order_by(Flat.created_at.desc()).limit(limit).offset(offset)).all()
    return {"status": "success", "flats": [flat_to_client(flat) for flat in flats], "pagination": {"limit": limit, "offset": offset, "total": total}}


@router.get("/applications/me")
def get_my_applications(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    applications = db.scalars(select(FlatApplication).where(FlatApplication.user_id == current_user.id)).all()
    return {"applications": [application_to_client(application) for application in applications]}


@router.get("/{flat_id}")
def get_flat(flat_id: str, db: Session = Depends(get_db)):
    flat = db.get(Flat, flat_id)
    if not flat or flat.status == "removed":
        raise HTTPException(status_code=404, detail="Flat not found")
    return {"status": "success", "flat": flat_to_client(flat)}


@router.post("/{flat_id}/applications", status_code=201)
def apply_for_flat(flat_id: str, payload: dict, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    flat_uuid = uuid.UUID(flat_id)
    flat = db.get(Flat, flat_uuid)
    if not flat or flat.status != "active":
        raise HTTPException(status_code=404, detail="Flat not found")
    group_chat_id = uuid.UUID(payload["groupChatId"])
    is_member = db.scalar(
        select(ChatMember).where(ChatMember.chat_id == group_chat_id, ChatMember.user_id == current_user.id)
    )
    if not is_member:
        raise HTTPException(status_code=403, detail="You must be in the selected group chat")
    existing = db.scalar(
        select(FlatApplication).where(FlatApplication.flat_id == flat_uuid, FlatApplication.user_id == current_user.id)
    )
    if existing:
        return {"application": application_to_client(existing)}
    application = FlatApplication(
        flat_id=flat_uuid,
        group_chat_id=group_chat_id,
        user_id=current_user.id,
    )
    db.add(application)
    db.flush()
    if flat.owner_id:
        create_notification(
            db,
            flat.owner_id,
            "system",
            "New flat application",
            f"{current_user.name} applied for {flat.title}",
            {"flatId": str(flat.id), "applicationId": str(application.id)},
        )
    db.commit()
    db.refresh(application)
    return {"application": application_to_client(application)}


@router.get("/{flat_id}/applications")
def get_flat_applications(flat_id: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    applications = db.scalars(select(FlatApplication).where(FlatApplication.flat_id == uuid.UUID(flat_id))).all()
    return {"applications": [application_to_client(application) for application in applications]}


@router.put("/applications/{application_id}")
def update_application(application_id: str, payload: dict, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    application = db.get(FlatApplication, application_id)
    if not application:
        raise HTTPException(status_code=404, detail="Application not found")
    status = payload["status"]
    if status not in {"pending", "approved", "rejected"}:
        raise HTTPException(status_code=400, detail="Invalid application status")
    flat = db.get(Flat, application.flat_id)
    if flat and flat.owner_id and flat.owner_id != current_user.id and getattr(current_user, "role", "user") != "admin":
        raise HTTPException(status_code=403, detail="Only the flat owner or admin can update applications")
    application.status = status
    create_notification(
        db,
        application.user_id,
        "system",
        "Flat application updated",
        f"Your flat application was {status}",
        {"flatId": str(application.flat_id), "applicationId": str(application.id), "status": status},
    )
    db.commit()
    db.refresh(application)
    return {"application": application_to_client(application)}
