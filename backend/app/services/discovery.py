from datetime import datetime, timezone
from typing import Any

from ..models import Profile, User


def _budget_overlap(a: dict[str, Any], b: dict[str, Any]) -> bool:
    a_min, a_max = int(a.get("min", 0) or 0), int(a.get("max", 0) or 0)
    b_min, b_max = int(b.get("min", 0) or 0), int(b.get("max", 0) or 0)
    if not a_max or not b_max:
        return False
    return max(a_min, b_min) <= min(a_max, b_max)


def score_profile(
    current: Profile | None,
    candidate: Profile,
    candidate_user: User,
    semantic: dict[str, Any] | None = None,
) -> dict[str, Any]:
    score = 0
    reasons: dict[str, int] = {}
    if not current:
        return {"score": 0, "reasons": reasons}

    if semantic and semantic.get("available"):
        semantic_points = int(semantic.get("score", 0))
        reasons["semanticCompatibility"] = semantic_points
        score += semantic_points

    current_city = (current.city or current.location.get("city") or "").lower()
    candidate_city = (candidate.city or candidate.location.get("city") or "").lower()
    if current_city and current_city == candidate_city:
        reasons["city"] = 15
        score += 15

    if _budget_overlap(current.budget or {}, candidate.budget or {}):
        reasons["budget"] = 12
        score += 12

    if current.room_preference == candidate.room_preference or current.room_preference == "any":
        reasons["roomPreference"] = 6
        score += 6

    shared_languages = set(current.languages or []) & set(candidate.languages or [])
    if shared_languages:
        reasons["languages"] = 5
        score += 5

    current_move_in = getattr(current, "move_in_date", None)
    candidate_move_in = getattr(candidate, "move_in_date", None)
    if current_move_in and candidate_move_in and current_move_in == candidate_move_in:
        reasons["moveInTiming"] = 4
        score += 4

    if candidate_user.last_active:
        days = (datetime.now(timezone.utc) - candidate_user.last_active).days
        if days <= 7:
            reasons["recentActivity"] = 5
            score += 5

    return {"score": score, "reasons": reasons}
