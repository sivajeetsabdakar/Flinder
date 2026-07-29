import uuid
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import get_current_user
from ..models import Boost, Profile, ProfilePicture, User
from ..schemas import PictureRequest, ProfileRequest
from ..serializers import picture_to_client, profile_to_client
from ..services.storage import delete_object_by_url, upload_profile_image

router = APIRouter(prefix="/api/profile", tags=["profile"])


def resolve_user_id(raw_id: str, current_user: User) -> uuid.UUID:
    if raw_id == "me":
        return current_user.id
    parsed = uuid.UUID(raw_id)
    if parsed != current_user.id:
        raise HTTPException(status_code=403, detail="Access denied")
    return parsed


def completion_score(profile: Profile, photo_count: int) -> tuple[int, str]:
    score = 0
    if profile.bio and len(profile.bio.strip()) >= 20:
        score += 15
    if photo_count:
        score += 20
    if profile.location and (profile.city or profile.location.get("city")):
        score += 15
    if profile.budget:
        score += 10
    if profile.lifestyle:
        score += 15
    if profile.interests:
        score += 15
    if profile.room_preference and profile.gender_preference:
        score += 10
    step = "complete" if score >= 70 else "preferences" if score >= 45 else "photos" if score >= 20 else "basic"
    return score, step


@router.get("/{user_id}")
def get_profile(user_id: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    profile_user_id = resolve_user_id(user_id, current_user)
    profile = db.get(Profile, profile_user_id)
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")
    return {"success": True, "profile": profile_to_client(profile, current_user)}


@router.put("/{user_id}")
def update_profile(
    user_id: str,
    payload: ProfileRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    profile_user_id = resolve_user_id(user_id, current_user)
    profile = db.get(Profile, profile_user_id) or Profile(user_id=profile_user_id)
    profile.bio = payload.bio
    profile.generated_description = payload.generatedDescription
    profile.interests = payload.interests
    profile.location = payload.location
    profile.budget = payload.budget
    profile.room_preference = payload.roomPreference
    profile.gender_preference = payload.genderPreference
    profile.move_in_date = payload.moveInDate
    profile.lease_duration = payload.leaseDuration
    profile.lifestyle = payload.lifestyle
    profile.languages = payload.languages
    profile.city = payload.location.get("city") or payload.location.get("name")
    profile.country = payload.location.get("country")
    profile.latitude = payload.location.get("latitude") or payload.location.get("lat")
    profile.longitude = payload.location.get("longitude") or payload.location.get("lng")
    photo_count = db.query(ProfilePicture).filter(ProfilePicture.user_id == current_user.id).count()
    score, step = completion_score(profile, photo_count)
    profile.completion_score = score
    profile.onboarding_step = step
    current_user.profile_completed = score >= 70
    db.add(profile)
    db.commit()
    db.refresh(profile)
    return {"success": True, "message": "Profile updated successfully", "profile": profile_to_client(profile, current_user)}


@router.post("/photos")
def add_photo(payload: PictureRequest, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if payload.isPrimary:
        for picture in db.query(ProfilePicture).filter(ProfilePicture.user_id == current_user.id):
            picture.is_primary = False

    picture = ProfilePicture(user_id=current_user.id, url=payload.url, is_primary=payload.isPrimary)
    db.add(picture)
    db.commit()
    db.refresh(picture)
    return {"success": True, "message": "Photo uploaded successfully", "photo": picture_to_client(picture)}


@router.post("/photos/upload")
async def upload_photo(
    file: UploadFile = File(...),
    is_primary: bool = False,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    stored = await upload_profile_image(current_user.id, file)
    if is_primary:
        for existing in db.query(ProfilePicture).filter(ProfilePicture.user_id == current_user.id):
            existing.is_primary = False
    picture = ProfilePicture(user_id=current_user.id, url=stored.url, is_primary=is_primary)
    db.add(picture)
    profile = db.get(Profile, current_user.id)
    if profile:
        photo_count = db.query(ProfilePicture).filter(ProfilePicture.user_id == current_user.id).count() + 1
        score, step = completion_score(profile, photo_count)
        profile.completion_score = score
        profile.onboarding_step = step
        current_user.profile_completed = score >= 70
    db.commit()
    db.refresh(picture)
    return {"success": True, "message": "Photo uploaded successfully", "photo": picture_to_client(picture)}


@router.post("/boost")
def boost_profile(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    now = datetime.now(timezone.utc)
    boost = Boost(user_id=current_user.id, starts_at=now, expires_at=now + timedelta(hours=24), is_active=True)
    db.add(boost)
    db.commit()
    db.refresh(boost)
    return {"success": True, "boost": {"id": str(boost.id), "expiresAt": boost.expires_at.isoformat()}}


@router.delete("/photos/{picture_id}")
def delete_photo(picture_id: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    picture = db.get(ProfilePicture, picture_id)
    if not picture or picture.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Photo not found")
    delete_object_by_url(picture.url)
    db.delete(picture)
    db.commit()
    return {"success": True, "message": "Photo deleted successfully"}
