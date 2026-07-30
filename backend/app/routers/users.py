from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import get_current_user
from ..models import User
from ..serializers import user_to_client

router = APIRouter(prefix="/api/users", tags=["users"])


@router.get("/me")
def get_me(current_user: User = Depends(get_current_user)):
    return {"user": user_to_client(current_user)}


@router.post("/me/onboarding/skip")
def skip_onboarding(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    current_user.profile_questionnaire_skipped_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(current_user)
    return {"success": True, "user": user_to_client(current_user)}


@router.delete("/me/onboarding/skip")
def clear_onboarding_skip(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    current_user.profile_questionnaire_skipped_at = None
    db.commit()
    db.refresh(current_user)
    return {"success": True, "user": user_to_client(current_user)}


@router.get("/{user_id}")
def get_user(user_id: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    user = db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return {"user": user_to_client(user)}
