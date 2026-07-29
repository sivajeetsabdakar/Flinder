from __future__ import annotations

import uuid
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..models import Swipe, UserEmbedding
from .semantic_matching import CATEGORIES, cosine_similarity

MIN_SIGNAL_SWIPES = 4
MAX_LEARNING_POINTS = 15


def _empty_vector(size: int) -> list[float]:
    return [0.0 for _ in range(size)]


def _add_scaled(target: list[float], source: list[float] | None, weight: float) -> None:
    if not source or len(target) != len(source):
        return
    for index, value in enumerate(source):
        target[index] += float(value) * weight


def _normalize(vector: list[float]) -> list[float] | None:
    norm = sum(value * value for value in vector) ** 0.5
    if not norm:
        return None
    return [value / norm for value in vector]


def build_swipe_preference_model(db: Session, user_id: uuid.UUID, limit: int = 200) -> dict[str, Any]:
    swipes = db.scalars(
        select(Swipe)
        .where(Swipe.user_id == user_id)
        .order_by(Swipe.created_at.desc())
        .limit(limit)
    ).all()
    if not swipes:
        return {"available": False, "likeCount": 0, "passCount": 0, "vectors": {}}

    target_ids = [swipe.target_user_id for swipe in swipes]
    embeddings = {
        row.user_id: row
        for row in db.scalars(
            select(UserEmbedding).where(
                UserEmbedding.user_id.in_(target_ids),
                UserEmbedding.status == "ready",
            )
        ).all()
    }
    if not embeddings:
        return {"available": False, "likeCount": 0, "passCount": 0, "vectors": {}}

    vectors: dict[str, list[float]] = {}
    like_count = 0
    pass_count = 0
    for category in CATEGORIES:
        sample = next(
            (
                getattr(row, f"embedding_{category}", None)
                for row in embeddings.values()
                if getattr(row, f"embedding_{category}", None)
            ),
            None,
        )
        if not sample:
            continue
        accumulator = _empty_vector(len(sample))
        for swipe in swipes:
            embedding = embeddings.get(swipe.target_user_id)
            if not embedding:
                continue
            source = getattr(embedding, f"embedding_{category}", None)
            if swipe.action == "like":
                if category == CATEGORIES[0]:
                    like_count += 1
                _add_scaled(accumulator, source, 1.0)
            elif swipe.action == "pass":
                if category == CATEGORIES[0]:
                    pass_count += 1
                _add_scaled(accumulator, source, -0.35)
        normalized = _normalize(accumulator)
        if normalized:
            vectors[category] = normalized

    available = bool(vectors) and (like_count + pass_count) >= MIN_SIGNAL_SWIPES and like_count > 0
    return {
        "available": available,
        "likeCount": like_count,
        "passCount": pass_count,
        "vectors": vectors,
    }


def swipe_learning_score(model: dict[str, Any], candidate: UserEmbedding | None) -> dict[str, Any]:
    if not model.get("available") or not candidate or candidate.status != "ready":
        return {"available": False, "score": 0, "categoryScores": {}, "confidence": 0}

    category_scores: dict[str, float] = {}
    total = 0.0
    count = 0
    for category, learned_vector in model.get("vectors", {}).items():
        score = cosine_similarity(learned_vector, getattr(candidate, f"embedding_{category}", None))
        normalized = max(0.0, min(1.0, (score + 1) / 2))
        category_scores[category] = round(normalized, 4)
        total += normalized
        count += 1

    if not count:
        return {"available": False, "score": 0, "categoryScores": {}, "confidence": 0}

    signal_count = int(model.get("likeCount", 0)) + int(model.get("passCount", 0))
    confidence = min(1.0, signal_count / 30)
    score = round((total / count) * MAX_LEARNING_POINTS * confidence)
    return {
        "available": True,
        "score": score,
        "categoryScores": category_scores,
        "confidence": round(confidence, 4),
    }
