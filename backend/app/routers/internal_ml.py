import uuid

from fastapi import APIRouter, Depends, Header, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..config import get_settings
from ..database import get_db
from ..models import UserEmbedding
from ..services.semantic_matching import rebuild_user_embedding

router = APIRouter(prefix="/internal/ml", tags=["internal-ml"])


def require_worker_token(x_ml_worker_token: str | None = Header(default=None)) -> None:
    settings = get_settings()
    if not settings.ml_worker_token or x_ml_worker_token != settings.ml_worker_token:
        raise HTTPException(status_code=401, detail="Invalid worker token")


@router.get("/health")
def health():
    return {"status": "ok", "service": "flinder-ml-worker"}


@router.post("/profiles/{user_id}/rebuild", dependencies=[Depends(require_worker_token)])
def rebuild_profile(user_id: str, db: Session = Depends(get_db)):
    try:
        row = rebuild_user_embedding(db, uuid.UUID(user_id))
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    return {
        "success": row.status == "ready",
        "userId": str(row.user_id),
        "status": row.status,
        "model": row.model_name,
        "lastEmbeddedAt": row.last_embedded_at.isoformat() if row.last_embedded_at else None,
        "error": row.error,
    }


@router.post("/profiles/rebuild-missing", dependencies=[Depends(require_worker_token)])
def rebuild_missing(limit: int = 25, db: Session = Depends(get_db)):
    rows = db.scalars(
        select(UserEmbedding)
        .where(UserEmbedding.status.in_(["missing", "stale", "failed"]))
        .order_by(UserEmbedding.updated_at.asc())
        .limit(max(1, min(limit, 100)))
    ).all()
    results = []
    for row in rows:
        rebuilt = rebuild_user_embedding(db, row.user_id)
        results.append({"userId": str(rebuilt.user_id), "status": rebuilt.status, "error": rebuilt.error})
    return {"success": True, "processed": len(results), "results": results}
