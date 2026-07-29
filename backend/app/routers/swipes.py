from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import get_current_user
from ..models import User
from .discovery import rewind_swipe

router = APIRouter(prefix="/api/swipes", tags=["swipes"])


@router.post("/rewind")
def rewind(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return rewind_swipe(current_user=current_user, db=db)
