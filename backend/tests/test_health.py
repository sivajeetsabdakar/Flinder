import os

os.environ["APP_ENV"] = "testing"
os.environ["DATABASE_URL"] = "postgresql+psycopg://user:pass@localhost/db"
os.environ["JWT_SECRET"] = "test-secret"
os.environ["GOOGLE_OAUTH_CLIENT_ID"] = "dummy.apps.googleusercontent.com"
os.environ["ML_WORKER_TOKEN"] = "test-worker-token"

from fastapi.testclient import TestClient

from app.main import app


def test_health_endpoint():
    client = TestClient(app)
    response = client.get("/api/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok", "service": "flinder-backend"}
    assert response.headers["x-request-id"]
    assert response.headers["x-content-type-options"] == "nosniff"


def test_worker_only_app_exposes_internal_ml_without_public_routes(monkeypatch):
    from app.config import get_settings
    import app.main as main_module
    from importlib import reload

    monkeypatch.setenv("WORKER_ONLY", "true")
    get_settings.cache_clear()

    worker_main = reload(main_module)
    client = TestClient(worker_main.app)

    assert client.get("/internal/ml/health").status_code == 200
    assert client.get("/api/health").status_code == 200
    assert client.get("/api/profile").status_code == 404

    monkeypatch.setenv("WORKER_ONLY", "false")
    get_settings.cache_clear()
    reload(main_module)
