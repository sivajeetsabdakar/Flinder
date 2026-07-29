import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import HTMLResponse
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import require_admin
from ..models import AdminAuditLog, Flat, FlatApplication, FlatReport, Match, Notification, User, UserReport
from ..schemas import AdminResolveRequest
from ..serializers import flat_report_to_client, user_report_to_client, user_to_client

router = APIRouter(prefix="/admin", tags=["admin"])


def audit(db: Session, admin: User, action: str, target_type: str, target_id: uuid.UUID | None, metadata: dict):
    db.add(AdminAuditLog(admin_id=admin.id, action=action, target_type=target_type, target_id=target_id, meta=metadata))


@router.get("", response_class=HTMLResponse)
def dashboard(_: User = Depends(require_admin), db: Session = Depends(get_db)):
    counts = {
        "users": db.scalar(select(func.count()).select_from(User)) or 0,
        "reports": db.scalar(select(func.count()).select_from(UserReport).where(UserReport.status == "open")) or 0,
        "flatReports": db.scalar(select(func.count()).select_from(FlatReport).where(FlatReport.status == "open")) or 0,
        "flats": db.scalar(select(func.count()).select_from(Flat)) or 0,
        "applications": db.scalar(select(func.count()).select_from(FlatApplication)) or 0,
        "matches": db.scalar(select(func.count()).select_from(Match)) or 0,
        "notifications": db.scalar(select(func.count()).select_from(Notification)) or 0,
    }
    cards = "".join(f"<li><strong>{key}</strong>: {value}</li>" for key, value in counts.items())
    return f"""
    <!doctype html>
    <html>
      <head><title>Flinder Admin</title><style>body{{font-family:Arial;margin:32px}}li{{margin:8px 0}}</style></head>
      <body>
        <h1>Flinder Admin</h1>
        <p>Protected backend dashboard. Use API routes for review actions.</p>
        <ul>{cards}</ul>
      </body>
    </html>
    """


@router.get("/summary")
def summary(_: User = Depends(require_admin), db: Session = Depends(get_db)):
    return {
        "users": db.scalar(select(func.count()).select_from(User)) or 0,
        "openUserReports": db.scalar(select(func.count()).select_from(UserReport).where(UserReport.status == "open")) or 0,
        "openFlatReports": db.scalar(select(func.count()).select_from(FlatReport).where(FlatReport.status == "open")) or 0,
        "flats": db.scalar(select(func.count()).select_from(Flat)) or 0,
        "applications": db.scalar(select(func.count()).select_from(FlatApplication)) or 0,
        "matches": db.scalar(select(func.count()).select_from(Match)) or 0,
    }


@router.get("/users")
def list_users(_: User = Depends(require_admin), db: Session = Depends(get_db)):
    users = db.scalars(select(User).order_by(User.created_at.desc()).limit(100)).all()
    return {"users": [user_to_client(user) for user in users]}


@router.get("/reports/users")
def list_user_reports(_: User = Depends(require_admin), db: Session = Depends(get_db)):
    reports = db.scalars(select(UserReport).order_by(UserReport.created_at.desc()).limit(100)).all()
    return {"reports": [user_report_to_client(report) for report in reports]}


@router.post("/reports/users/{report_id}/resolve")
def resolve_user_report(
    report_id: str,
    payload: AdminResolveRequest,
    admin: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    report = db.get(UserReport, uuid.UUID(report_id))
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    if payload.status not in {"resolved", "dismissed", "reviewing"}:
        raise HTTPException(status_code=400, detail="Invalid report status")
    report.status = payload.status
    report.admin_notes = payload.adminNotes
    if payload.status in {"resolved", "dismissed"}:
        report.resolved_by = admin.id
        report.resolved_at = datetime.now(timezone.utc)
    if payload.suspendUser:
        user = db.get(User, report.reported_user_id)
        if user:
            user.account_status = "suspended"
    audit(db, admin, "resolve_user_report", "user_report", report.id, {"status": payload.status})
    db.commit()
    return {"success": True, "report": user_report_to_client(report)}


@router.get("/reports/flats")
def list_flat_reports(_: User = Depends(require_admin), db: Session = Depends(get_db)):
    reports = db.scalars(select(FlatReport).order_by(FlatReport.created_at.desc()).limit(100)).all()
    return {"reports": [flat_report_to_client(report) for report in reports]}


@router.post("/reports/flats/{report_id}/resolve")
def resolve_flat_report(
    report_id: str,
    payload: AdminResolveRequest,
    admin: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    report = db.get(FlatReport, uuid.UUID(report_id))
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    if payload.status not in {"resolved", "dismissed", "reviewing"}:
        raise HTTPException(status_code=400, detail="Invalid report status")
    report.status = payload.status
    report.admin_notes = payload.adminNotes
    if payload.status in {"resolved", "dismissed"}:
        report.resolved_by = admin.id
        report.resolved_at = datetime.now(timezone.utc)
    if payload.removeFlat:
        flat = db.get(Flat, report.flat_id)
        if flat:
            flat.status = "removed"
    audit(db, admin, "resolve_flat_report", "flat_report", report.id, {"status": payload.status})
    db.commit()
    return {"success": True, "report": flat_report_to_client(report)}
