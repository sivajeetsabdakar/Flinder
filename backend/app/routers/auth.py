from datetime import date, datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..config import get_settings
from ..database import get_db
from ..models import User
from ..schemas import GoogleAuthRequest, LoginRequest, RegisterRequest
from ..security import create_access_token, hash_password, verify_password
from ..serializers import user_to_client

router = APIRouter(prefix="/api/auth", tags=["auth"])


def admin_role_for_email(email: str) -> str:
    settings = get_settings()
    return "admin" if email.lower() in settings.admin_email_set else "user"


def parse_birth_date(value: str) -> date:
    return date.fromisoformat(value)


@router.post("/register")
def register(payload: RegisterRequest, db: Session = Depends(get_db)):
    role = admin_role_for_email(payload.email)
    existing = db.scalar(select(User).where(User.email == payload.email))
    if existing:
        raise HTTPException(status_code=400, detail="Email is already registered")

    user = User(
        email=payload.email,
        password=hash_password(payload.password),
        name=payload.name,
        phone=payload.phone,
        date_of_birth=parse_birth_date(payload.dateOfBirth),
        gender=payload.gender,
        verification_status={"email": False, "phone": False},
        online_status="online",
        last_active=datetime.now(timezone.utc),
        role=role,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    token = create_access_token(str(user.id), {"email": user.email, "name": user.name})
    return {"success": True, "message": "User registered successfully", "token": token, "user": user_to_client(user)}


@router.post("/login")
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    user = db.scalar(select(User).where(User.email == payload.email))
    if not user or not verify_password(payload.password, user.password):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    user.online_status = "online"
    user.last_active = datetime.now(timezone.utc)
    db.commit()

    token = create_access_token(str(user.id), {"email": user.email, "name": user.name})
    return {"success": True, "message": "Login successful", "token": token, "user": user_to_client(user)}


@router.post("/google")
def google_login(payload: GoogleAuthRequest, db: Session = Depends(get_db)):
    settings = get_settings()
    if not settings.google_oauth_client_id:
        raise HTTPException(status_code=500, detail="GOOGLE_OAUTH_CLIENT_ID is not configured")

    try:
        google_user = id_token.verify_oauth2_token(
            payload.idToken,
            google_requests.Request(),
            settings.google_oauth_client_id,
        )
    except ValueError:
        raise HTTPException(status_code=401, detail="Invalid Google ID token")

    if not google_user.get("email_verified"):
        raise HTTPException(status_code=401, detail="Google email is not verified")

    google_sub = google_user["sub"]
    email = google_user["email"]
    name = google_user.get("name") or email.split("@")[0]
    role = admin_role_for_email(email)

    user = db.scalar(select(User).where(User.google_sub == google_sub))
    if not user:
        user = db.scalar(select(User).where(User.email == email))

    if user:
        user.google_sub = google_sub
        user.auth_provider = "google"
        user.name = user.name or name
        user.online_status = "online"
        user.last_active = datetime.now(timezone.utc)
        if role == "admin":
            user.role = "admin"
    else:
        user = User(
            google_sub=google_sub,
            auth_provider="google",
            email=email,
            password=hash_password(f"google:{google_sub}"),
            name=name,
            gender="prefer_not_to_say",
            verification_status={"email": True, "phone": False},
            online_status="online",
            last_active=datetime.now(timezone.utc),
            role=role,
        )
        db.add(user)

    db.commit()
    db.refresh(user)

    token = create_access_token(str(user.id), {"email": user.email, "name": user.name})
    return {"success": True, "message": "Google login successful", "token": token, "user": user_to_client(user)}
