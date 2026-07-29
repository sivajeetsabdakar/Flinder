from __future__ import annotations

import hashlib
import json
import math
import uuid
from datetime import datetime, timezone
from typing import Any

import httpx
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..config import get_settings
from ..models import Preference, Profile, UserEmbedding


CATEGORIES = ("hobbies", "interests", "traits", "personality", "likes", "dislikes")
CATEGORY_WEIGHTS = {
    "hobbies": 0.10,
    "interests": 0.20,
    "traits": 0.20,
    "personality": 0.20,
    "likes": 0.15,
    "dislikes": 0.15,
}
CONFLICT_WEIGHT = 0.18
_model = None


def _flatten(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, str):
        return value.strip()
    if isinstance(value, bool):
        return "yes" if value else "no"
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, list):
        return ", ".join(part for part in (_flatten(item) for item in value) if part)
    if isinstance(value, dict):
        parts = []
        for key, item in sorted(value.items()):
            text = _flatten(item)
            if text:
                parts.append(f"{key}: {text}")
        return "; ".join(parts)
    return str(value).strip()


def _jsonable_profile(profile: Profile, preference: Preference | None) -> dict[str, Any]:
    return {
        "bio": profile.bio,
        "generatedDescription": profile.generated_description or {},
        "interests": profile.interests or [],
        "location": profile.location or {},
        "budget": profile.budget or {},
        "roomPreference": profile.room_preference,
        "genderPreference": profile.gender_preference,
        "moveInDate": profile.move_in_date,
        "leaseDuration": profile.lease_duration,
        "lifestyle": profile.lifestyle or {},
        "languages": profile.languages or [],
        "preferences": {
            "critical": preference.critical if preference else {},
            "nonCritical": preference.non_critical if preference else {},
            "interests": preference.interests if preference else [],
        },
    }


def source_hash(profile: Profile, preference: Preference | None) -> str:
    payload = json.dumps(_jsonable_profile(profile, preference), sort_keys=True, default=str)
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def parse_llm_traits(raw: str) -> dict[str, Any]:
    text = raw.strip()
    if not text:
        return {}
    if text.startswith("```"):
        text = text.strip("`")
        if text.lower().startswith("json"):
            text = text[4:].strip()
    start = text.find("{")
    end = text.rfind("}")
    if start >= 0 and end > start:
        text = text[start : end + 1]
    try:
        parsed = json.loads(text)
    except json.JSONDecodeError:
        return {}
    return parsed if isinstance(parsed, dict) else {}


def build_llm_prompt(profile: Profile, preference: Preference | None) -> str:
    payload = json.dumps(_jsonable_profile(profile, preference), indent=2, default=str)
    return (
        "Extract roommate compatibility signals from this Flinder profile. "
        "Return only JSON with keys hobbies, interests, traits, personality, likes, dislikes. "
        "Each value must be a short natural-language string, not an array. "
        "Do not include sensitive guesses, protected-class inferences, or diagnoses.\n\n"
        f"Profile:\n{payload}"
    )


def fetch_llm_traits(profile: Profile, preference: Preference | None) -> dict[str, Any]:
    settings = get_settings()
    if not settings.ai_text_api_base_url or not settings.ai_text_api_token:
        return {}
    response = httpx.post(
        f"{settings.ai_text_api_base_url.rstrip('/')}/ask",
        headers={"X-AI-Token": settings.ai_text_api_token},
        json={"prompt": build_llm_prompt(profile, preference), "temperature": 0.2, "max_output_tokens": 600},
        timeout=20,
    )
    response.raise_for_status()
    return parse_llm_traits(response.json().get("response", ""))


def build_canonical_texts(profile: Profile, preference: Preference | None, llm_traits: dict[str, Any] | None = None) -> dict[str, str]:
    llm_traits = llm_traits or {}
    generated = profile.generated_description or {}
    lifestyle = profile.lifestyle or {}
    non_critical = preference.non_critical if preference else {}
    critical = preference.critical if preference else {}
    preference_interests = preference.interests if preference else []

    texts = {
        "hobbies": " ".join(filter(None, [
            _flatten(llm_traits.get("hobbies")),
            _flatten(generated.get("hobbies")),
            _flatten(non_critical.get("hobbies")),
        ])),
        "interests": " ".join(filter(None, [
            _flatten(llm_traits.get("interests")),
            _flatten(profile.interests),
            _flatten(preference_interests),
        ])),
        "traits": " ".join(filter(None, [
            _flatten(llm_traits.get("traits")),
            _flatten(lifestyle),
            _flatten(non_critical.get("traits")),
            _flatten(critical.get("roommatePreferences")),
        ])),
        "personality": " ".join(filter(None, [
            _flatten(llm_traits.get("personality")),
            _flatten(generated.get("personality")),
            _flatten(generated.get("summary")),
            _flatten(profile.bio),
        ])),
        "likes": " ".join(filter(None, [
            _flatten(llm_traits.get("likes")),
            _flatten(generated.get("likes")),
            _flatten(non_critical.get("likes")),
            _flatten(non_critical.get("preferredActivities")),
        ])),
        "dislikes": " ".join(filter(None, [
            _flatten(llm_traits.get("dislikes")),
            _flatten(generated.get("dislikes")),
            _flatten(non_critical.get("dislikes")),
            _flatten(non_critical.get("dealBreakers")),
        ])),
    }
    return {key: value.strip() or profile.bio for key, value in texts.items()}


def cosine_similarity(left: list[float] | None, right: list[float] | None) -> float:
    if not left or not right or len(left) != len(right):
        return 0.0
    dot = sum(a * b for a, b in zip(left, right))
    left_norm = math.sqrt(sum(a * a for a in left))
    right_norm = math.sqrt(sum(b * b for b in right))
    if not left_norm or not right_norm:
        return 0.0
    return max(-1.0, min(1.0, dot / (left_norm * right_norm)))


def semantic_similarity(current: UserEmbedding | None, candidate: UserEmbedding | None) -> dict[str, Any]:
    if not current or not candidate or current.status != "ready" or candidate.status != "ready":
        return {"available": False, "score": 0, "categoryScores": {}, "conflictPenalty": 0}

    category_scores: dict[str, float] = {}
    weighted = 0.0
    total_weight = 0.0
    for category in CATEGORIES:
        score = cosine_similarity(
            getattr(current, f"embedding_{category}", None),
            getattr(candidate, f"embedding_{category}", None),
        )
        normalized = (score + 1) / 2
        category_scores[category] = round(normalized, 4)
        weighted += normalized * CATEGORY_WEIGHTS[category]
        total_weight += CATEGORY_WEIGHTS[category]

    conflict = 0.0
    conflict += max(0.0, cosine_similarity(current.embedding_likes, candidate.embedding_dislikes))
    conflict += max(0.0, cosine_similarity(current.embedding_dislikes, candidate.embedding_likes))
    conflict = min(1.0, conflict * CONFLICT_WEIGHT)
    final = max(0.0, min(1.0, (weighted / total_weight if total_weight else 0.0) - conflict))
    return {
        "available": True,
        "score": round(final * 60),
        "categoryScores": category_scores,
        "conflictPenalty": round(conflict, 4),
    }


def mark_embedding_stale(db: Session, user_id: uuid.UUID) -> None:
    profile = db.get(Profile, user_id)
    if not profile:
        return
    preference = db.scalar(select(Preference).where(Preference.user_id == user_id))
    current_hash = source_hash(profile, preference)
    row = db.get(UserEmbedding, user_id)
    if not row:
        row = UserEmbedding(user_id=user_id)
        db.add(row)
    if row.source_hash != current_hash or row.status in {"missing", "failed"}:
        row.source_hash = current_hash
        row.status = "stale"
        row.error = None


def trigger_embedding_rebuild(user_id: uuid.UUID) -> None:
    settings = get_settings()
    if not settings.ml_worker_url or not settings.ml_worker_token:
        return
    try:
        httpx.post(
            f"{settings.ml_worker_url.rstrip('/')}/internal/ml/profiles/{user_id}/rebuild",
            headers={"X-ML-Worker-Token": settings.ml_worker_token},
            timeout=1.5,
        )
    except Exception:
        return


def _load_model():
    global _model
    if _model is None:
        try:
            from sentence_transformers import SentenceTransformer
        except ImportError as exc:
            raise RuntimeError("sentence-transformers is not installed in this container") from exc
        _model = SentenceTransformer(get_settings().semantic_model_name)
    return _model


def rebuild_user_embedding(db: Session, user_id: uuid.UUID) -> UserEmbedding:
    profile = db.get(Profile, user_id)
    if not profile:
        raise ValueError("Profile not found")
    preference = db.scalar(select(Preference).where(Preference.user_id == user_id))
    row = db.get(UserEmbedding, user_id) or UserEmbedding(user_id=user_id)
    db.add(row)
    current_hash = source_hash(profile, preference)

    try:
        llm_traits = fetch_llm_traits(profile, preference)
    except Exception as exc:
        llm_traits = {"_error": str(exc)}

    texts = build_canonical_texts(profile, preference, llm_traits if "_error" not in llm_traits else {})
    try:
        model = _load_model()
        vectors = model.encode([texts[category] for category in CATEGORIES], normalize_embeddings=True)
        for category, vector in zip(CATEGORIES, vectors):
            setattr(row, f"embedding_{category}", [float(value) for value in vector.tolist()])
        row.model_name = get_settings().semantic_model_name
        row.source_hash = current_hash
        row.llm_traits = llm_traits
        row.canonical_text = texts
        row.status = "ready"
        row.error = None
        row.last_embedded_at = datetime.now(timezone.utc)
    except Exception as exc:
        row.source_hash = current_hash
        row.llm_traits = llm_traits
        row.canonical_text = texts
        row.status = "failed"
        row.error = str(exc)
    db.commit()
    db.refresh(row)
    return row
