from datetime import datetime, timezone
from typing import Any

from ..models import Profile, User


def _budget_overlap(a: dict[str, Any], b: dict[str, Any]) -> bool:
    a_min, a_max = int(a.get("min", 0) or 0), int(a.get("max", 0) or 0)
    b_min, b_max = int(b.get("min", 0) or 0), int(b.get("max", 0) or 0)
    if not a_max or not b_max:
        return False
    return max(a_min, b_min) <= min(a_max, b_max)


def score_profile(current: Profile | None, candidate: Profile, candidate_user: User) -> dict[str, Any]:
    score = 0
    reasons: dict[str, int] = {}
    if not current:
        return {"score": 0, "reasons": reasons}

    current_city = (current.city or current.location.get("city") or "").lower()
    candidate_city = (candidate.city or candidate.location.get("city") or "").lower()
    if current_city and current_city == candidate_city:
        reasons["city"] = 25
        score += 25

    if _budget_overlap(current.budget or {}, candidate.budget or {}):
        reasons["budget"] = 20
        score += 20

    if current.room_preference == candidate.room_preference or current.room_preference == "any":
        reasons["roomPreference"] = 10
        score += 10

    shared_interests = set(current.interests or []) & set(candidate.interests or [])
    if shared_interests:
        points = min(15, len(shared_interests) * 3)
        reasons["interests"] = points
        score += points

    shared_languages = set(current.languages or []) & set(candidate.languages or [])
    if shared_languages:
        reasons["languages"] = 5
        score += 5

    lifestyle_matches = 0
    for key, value in (current.lifestyle or {}).items():
        if (candidate.lifestyle or {}).get(key) == value:
            lifestyle_matches += 1
    if lifestyle_matches:
        points = min(15, lifestyle_matches * 3)
        reasons["lifestyle"] = points
        score += points

    if candidate_user.last_active:
        days = (datetime.now(timezone.utc) - candidate_user.last_active).days
        if days <= 7:
            reasons["recentActivity"] = 5
            score += 5

    return {"score": score, "reasons": reasons}
