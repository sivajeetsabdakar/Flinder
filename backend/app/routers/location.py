import urllib.parse

import requests
from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..config import get_settings
from ..database import get_db
from ..deps import get_current_user
from ..models import GeocodeCache, User
from ..schemas import GeocodeRequest

router = APIRouter(prefix="/api/location", tags=["location"])


@router.post("/search")
def geocode(payload: GeocodeRequest, _: User = Depends(get_current_user), db: Session = Depends(get_db)):
    query = " ".join(payload.query.strip().lower().split())
    cached = db.scalar(select(GeocodeCache).where(GeocodeCache.query == query))
    if cached:
        return {"success": True, "source": "cache", "results": cached.result}

    settings = get_settings()
    url = "https://nominatim.openstreetmap.org/search?" + urllib.parse.urlencode(
        {"q": payload.query, "format": "json", "limit": 5, "addressdetails": 1}
    )
    response = requests.get(url, headers={"User-Agent": settings.nominatim_user_agent}, timeout=10)
    response.raise_for_status()
    results = [
        {
            "name": item.get("display_name"),
            "latitude": float(item["lat"]),
            "longitude": float(item["lon"]),
            "city": (item.get("address") or {}).get("city") or (item.get("address") or {}).get("town"),
            "country": (item.get("address") or {}).get("country"),
            "attribution": "© OpenStreetMap contributors",
        }
        for item in response.json()
    ]
    db.add(GeocodeCache(query=query, result=results))
    db.commit()
    return {"success": True, "source": "nominatim", "results": results}
