import os

os.environ["APP_ENV"] = "testing"
os.environ["DATABASE_URL"] = "postgresql+psycopg://user:pass@localhost/db"
os.environ["JWT_SECRET"] = "test-secret"
os.environ["GOOGLE_OAUTH_CLIENT_ID"] = "dummy.apps.googleusercontent.com"

from fastapi.testclient import TestClient

from app.main import app
from app.services.discovery import score_profile


def test_photo_upload_requires_auth():
    client = TestClient(app)
    response = client.post("/api/profile/photos/upload")

    assert response.status_code in {401, 422}


def test_admin_dashboard_requires_auth():
    client = TestClient(app)
    response = client.get("/admin")

    assert response.status_code == 401


def test_discovery_score_prefers_shared_city_budget_and_interests():
    class ProfileStub:
        city = "Mumbai"
        location = {"city": "Mumbai"}
        budget = {"min": 10000, "max": 25000}
        room_preference = "private"
        interests = ["music", "fitness"]
        languages = ["English", "Hindi"]
        lifestyle = {"smoking": "no", "schedule": "early"}

    class CandidateStub:
        city = "Mumbai"
        location = {"city": "Mumbai"}
        budget = {"min": 15000, "max": 30000}
        room_preference = "private"
        interests = ["music", "gaming"]
        languages = ["English"]
        lifestyle = {"smoking": "no", "schedule": "late"}

    class UserStub:
        last_active = None

    result = score_profile(ProfileStub(), CandidateStub(), UserStub())

    assert result["score"] >= 60
    assert "city" in result["reasons"]
    assert "budget" in result["reasons"]
