import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import and_, or_, select
from sqlalchemy.orm import Session, selectinload

from ..database import get_db
from ..deps import get_current_user
from ..models import Boost, Match, Profile, Swipe, SwipeRewind, User, UserBlock
from ..schemas import SwipeRequest
from ..serializers import profile_to_client
from ..services.discovery import score_profile
from ..services.notifications import create_notification

router = APIRouter(prefix="/api/discover", tags=["discovery"])


@router.get("")
def discover(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    current_profile = db.get(Profile, current_user.id)
    if not current_profile or getattr(current_profile, "completion_score", 0) < 70:
        raise HTTPException(status_code=403, detail="Complete your profile before discovering matches")
    swiped_targets = select(Swipe.target_user_id).where(Swipe.user_id == current_user.id)
    blocked_users = select(UserBlock.blocked_id).where(UserBlock.blocker_id == current_user.id)
    blocked_by = select(UserBlock.blocker_id).where(UserBlock.blocked_id == current_user.id)
    profiles = db.scalars(
        select(Profile)
        .options(selectinload(Profile.user), selectinload(Profile.pictures))
        .where(Profile.user_id != current_user.id)
        .where(Profile.user_id.not_in(swiped_targets))
        .where(Profile.user_id.not_in(blocked_users))
        .where(Profile.user_id.not_in(blocked_by))
        .limit(100)
    ).all()
    active_boosts = {
        row.user_id
        for row in db.scalars(
            select(Boost).where(Boost.is_active.is_(True), Boost.expires_at > datetime.now(timezone.utc))
        ).all()
    }
    scored = []
    for profile in profiles:
        scoring = score_profile(current_profile, profile, profile.user)
        boost = 30 if profile.user_id in active_boosts else 0
        data = profile_to_client(profile, profile.user)
        data["compatibility"] = {"score": scoring["score"] + boost, "reasons": scoring["reasons"], "boosted": bool(boost)}
        scored.append(data)
    scored.sort(key=lambda item: item["compatibility"]["score"], reverse=True)
    return {"success": True, "profiles": scored[:25]}


@router.post("/swipe")
def swipe(payload: SwipeRequest, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    target_id = uuid.UUID(payload.targetUserId)
    if target_id == current_user.id:
        raise HTTPException(status_code=400, detail="You cannot swipe yourself")
    if db.scalar(select(UserBlock).where(or_(
        and_(UserBlock.blocker_id == current_user.id, UserBlock.blocked_id == target_id),
        and_(UserBlock.blocker_id == target_id, UserBlock.blocked_id == current_user.id),
    ))):
        raise HTTPException(status_code=403, detail="You cannot interact with this user")
    action = "like" if payload.action == "like" else "pass"

    existing = db.scalar(
        select(Swipe).where(Swipe.user_id == current_user.id, Swipe.target_user_id == target_id)
    )
    if existing:
        existing.action = action
    else:
        existing = Swipe(user_id=current_user.id, target_user_id=target_id, action=action)
        db.add(existing)

    if action == "like":
        reciprocal = db.scalar(
            select(Swipe).where(
                Swipe.user_id == target_id,
                Swipe.target_user_id == current_user.id,
                Swipe.action == "like",
            )
        )
        if reciprocal:
            first, second = sorted([current_user.id, target_id], key=str)
            match = db.scalar(
                select(Match).where(
                    or_(
                        and_(Match.user_id_1 == first, Match.user_id_2 == second),
                        and_(Match.user_id_1 == second, Match.user_id_2 == first),
                    )
                )
            )
            if not match:
                db.add(Match(user_id_1=first, user_id_2=second))
                create_notification(
                    db,
                    target_id,
                    "match",
                    "New match",
                    f"You matched with {current_user.name}",
                    {"userId": str(current_user.id)},
                )
                create_notification(
                    db,
                    current_user.id,
                    "match",
                    "New match",
                    "You have a new match",
                    {"userId": str(target_id)},
                )

    db.commit()
    return {"success": True, "message": "Swipe recorded"}


@router.post("/swipe/rewind")
def rewind_swipe(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    swipe = db.scalar(
        select(Swipe)
        .where(Swipe.user_id == current_user.id)
        .order_by(Swipe.created_at.desc())
        .limit(1)
    )
    if not swipe:
        raise HTTPException(status_code=404, detail="No swipe available to rewind")
    rewind = SwipeRewind(user_id=current_user.id, swipe_id=swipe.id, target_user_id=swipe.target_user_id)
    target_user_id = swipe.target_user_id
    db.add(rewind)
    db.delete(swipe)
    db.commit()
    return {"success": True, "rewoundTargetUserId": str(target_user_id)}


@router.get("/matches")
def matches(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    rows = db.scalars(
        select(Match).where(
            or_(Match.user_id_1 == current_user.id, Match.user_id_2 == current_user.id),
            Match.status == "active",
        )
    ).all()
    return {"success": True, "matches": [{"id": str(row.id), "userId1": str(row.user_id_1), "userId2": str(row.user_id_2)} for row in rows]}


@router.get("/likes")
def likes(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    liked_by = select(Swipe.user_id).where(Swipe.target_user_id == current_user.id, Swipe.action == "like")
    blocked_users = select(UserBlock.blocked_id).where(UserBlock.blocker_id == current_user.id)
    blocked_by = select(UserBlock.blocker_id).where(UserBlock.blocked_id == current_user.id)
    profiles = db.scalars(
        select(Profile)
        .options(selectinload(Profile.user), selectinload(Profile.pictures))
        .where(Profile.user_id.in_(liked_by))
        .where(Profile.user_id.not_in(blocked_users))
        .where(Profile.user_id.not_in(blocked_by))
    ).all()
    return {"success": True, "profiles": [profile_to_client(profile, profile.user) for profile in profiles]}


@router.post("/likes/{like_id}/respond")
def respond_to_like(like_id: str, payload: dict, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if payload.get("isAccepted"):
        target_id = uuid.UUID(payload["userId"])
        db.add(Swipe(user_id=current_user.id, target_user_id=target_id, action="like"))
    else:
        swipe = db.get(Swipe, like_id)
        if swipe and swipe.target_user_id == current_user.id:
            db.delete(swipe)
    db.commit()
    return {"success": True}
