from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import get_current_user
from ..models import Preference, User
from ..schemas import PreferencesRequest
from ..serializers import preference_to_client
from ..services.semantic_matching import mark_embedding_stale, trigger_embedding_rebuild

router = APIRouter(prefix="/api/preferences", tags=["preferences"])


@router.get("")
def get_preferences(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    preference = db.scalar(select(Preference).where(Preference.user_id == current_user.id))
    if not preference:
        raise HTTPException(status_code=404, detail="Preferences not found")
    return {"success": True, "preferences": preference_to_client(preference)}


@router.put("")
def update_preferences(
    payload: PreferencesRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    preference = db.scalar(select(Preference).where(Preference.user_id == current_user.id))
    if not preference:
        preference = Preference(user_id=current_user.id)
    preference.critical = payload.critical
    preference.non_critical = payload.nonCritical
    preference.discovery_settings = payload.discoverySettings
    preference.interests = payload.interests
    db.add(preference)
    mark_embedding_stale(db, current_user.id)
    db.commit()
    db.refresh(preference)
    trigger_embedding_rebuild(current_user.id)
    return {"success": True, "message": "Preferences updated successfully", "preferences": preference_to_client(preference)}
