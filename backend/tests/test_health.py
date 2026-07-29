import os

os.environ["APP_ENV"] = "testing"
os.environ["DATABASE_URL"] = "postgresql+psycopg://user:pass@localhost/db"
os.environ["JWT_SECRET"] = "test-secret"
os.environ["GOOGLE_OAUTH_CLIENT_ID"] = "dummy.apps.googleusercontent.com"

from fastapi.testclient import TestClient

from app.main import app


def test_health_endpoint():
    client = TestClient(app)
    response = client.get("/api/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok", "service": "flinder-backend"}
    assert response.headers["x-request-id"]
    assert response.headers["x-content-type-options"] == "nosniff"
