import uuid

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import get_current_user
from ..models import Flat, FlatReport, User, UserBlock, UserReport
from ..schemas import BlockUserRequest, ReportFlatRequest, ReportUserRequest
from ..serializers import block_to_client, flat_report_to_client, user_report_to_client

router = APIRouter(prefix="/api", tags=["safety"])


@router.post("/reports")
def report_user(payload: ReportUserRequest, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    target_id = uuid.UUID(payload.userId)
    if target_id == current_user.id:
        raise HTTPException(status_code=400, detail="You cannot report yourself")
    if not db.get(User, target_id):
        raise HTTPException(status_code=404, detail="User not found")
    report = UserReport(
        reporter_id=current_user.id,
        reported_user_id=target_id,
        reason=payload.reason,
        details=payload.details,
    )
    db.add(report)
    db.commit()
    db.refresh(report)
    return {"success": True, "report": user_report_to_client(report)}


@router.post("/flat-reports")
def report_flat(payload: ReportFlatRequest, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    flat_id = uuid.UUID(payload.flatId)
    if not db.get(Flat, flat_id):
        raise HTTPException(status_code=404, detail="Flat not found")
    report = FlatReport(reporter_id=current_user.id, flat_id=flat_id, reason=payload.reason, details=payload.details)
    db.add(report)
    db.commit()
    db.refresh(report)
    return {"success": True, "report": flat_report_to_client(report)}


@router.post("/blocks")
def block_user(payload: BlockUserRequest, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    blocked_id = uuid.UUID(payload.userId)
    if blocked_id == current_user.id:
        raise HTTPException(status_code=400, detail="You cannot block yourself")
    if not db.get(User, blocked_id):
        raise HTTPException(status_code=404, detail="User not found")
    block = db.scalar(
        select(UserBlock).where(UserBlock.blocker_id == current_user.id, UserBlock.blocked_id == blocked_id)
    ) or UserBlock(blocker_id=current_user.id, blocked_id=blocked_id)
    block.reason = payload.reason
    db.add(block)
    db.commit()
    db.refresh(block)
    return {"success": True, "block": block_to_client(block)}


@router.delete("/blocks/{user_id}")
def unblock_user(user_id: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    block = db.scalar(
        select(UserBlock).where(UserBlock.blocker_id == current_user.id, UserBlock.blocked_id == uuid.UUID(user_id))
    )
    if block:
        db.delete(block)
        db.commit()
    return {"success": True}
