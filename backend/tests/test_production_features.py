import os

os.environ["APP_ENV"] = "testing"
os.environ["DATABASE_URL"] = "postgresql+psycopg://user:pass@localhost/db"
os.environ["JWT_SECRET"] = "test-secret"
os.environ["GOOGLE_OAUTH_CLIENT_ID"] = "dummy.apps.googleusercontent.com"
os.environ["ML_WORKER_TOKEN"] = "test-worker-token"

from fastapi.testclient import TestClient

from app.main import app
from app.models import UserEmbedding
from app.services.discovery import score_profile
from app.services.semantic_matching import build_canonical_texts, cosine_similarity, parse_llm_traits, semantic_similarity
from app.services.swipe_learning import swipe_learning_score


def test_photo_upload_requires_auth():
    client = TestClient(app)
    response = client.post("/api/profile/photos/upload")

    assert response.status_code in {401, 422}


def test_admin_dashboard_requires_auth():
    client = TestClient(app)
    response = client.get("/admin")

    assert response.status_code == 401


def test_onboarding_skip_requires_auth():
    client = TestClient(app)
    response = client.post("/api/users/me/onboarding/skip")

    assert response.status_code == 401


def test_discovery_score_keeps_practical_fit_without_semantic_data():
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

    assert result["score"] >= 30
    assert "city" in result["reasons"]
    assert "budget" in result["reasons"]


def test_semantic_score_is_primary_signal_when_embeddings_exist():
    current = UserEmbedding(
        status="ready",
        embedding_hobbies=[1.0, 0.0],
        embedding_interests=[1.0, 0.0],
        embedding_traits=[1.0, 0.0],
        embedding_personality=[1.0, 0.0],
        embedding_likes=[1.0, 0.0],
        embedding_dislikes=[0.0, 1.0],
    )
    close = UserEmbedding(
        status="ready",
        embedding_hobbies=[0.95, 0.05],
        embedding_interests=[0.95, 0.05],
        embedding_traits=[0.95, 0.05],
        embedding_personality=[0.95, 0.05],
        embedding_likes=[0.95, 0.05],
        embedding_dislikes=[0.0, 1.0],
    )
    far = UserEmbedding(
        status="ready",
        embedding_hobbies=[0.0, 1.0],
        embedding_interests=[0.0, 1.0],
        embedding_traits=[0.0, 1.0],
        embedding_personality=[0.0, 1.0],
        embedding_likes=[0.0, 1.0],
        embedding_dislikes=[1.0, 0.0],
    )

    assert semantic_similarity(current, close)["score"] > semantic_similarity(current, far)["score"]


def test_llm_parser_accepts_wrapped_json_and_falls_back():
    parsed = parse_llm_traits('```json\n{"traits":"quiet and tidy","likes":"calm evenings"}\n```')

    assert parsed["traits"] == "quiet and tidy"
    assert parse_llm_traits("not json") == {}


def test_canonical_text_builder_handles_sparse_profile_fields():
    class ProfileStub:
        bio = "I prefer calm homes and usually cook after work."
        generated_description = None
        interests = ["reading", "music"]
        location = {}
        budget = {}
        room_preference = "private"
        gender_preference = "any_gender"
        move_in_date = "flexible"
        lease_duration = "flexible"
        lifestyle = {"noise": "quiet", "cleanliness": "tidy"}
        languages = ["English"]

    texts = build_canonical_texts(ProfileStub(), None, {"dislikes": "loud parties"})

    assert "reading" in texts["interests"]
    assert "quiet" in texts["traits"]
    assert "loud parties" in texts["dislikes"]


def test_cosine_similarity_handles_close_and_unrelated_vectors():
    assert cosine_similarity([1, 0], [0.9, 0.1]) > cosine_similarity([1, 0], [0, 1])


def test_swipe_learning_prefers_profiles_close_to_liked_history():
    model = {
        "available": True,
        "likeCount": 8,
        "passCount": 4,
        "vectors": {
            "interests": [1.0, 0.0],
            "personality": [1.0, 0.0],
        },
    }
    close = UserEmbedding(status="ready", embedding_interests=[0.95, 0.05], embedding_personality=[0.9, 0.1])
    far = UserEmbedding(status="ready", embedding_interests=[0.0, 1.0], embedding_personality=[0.0, 1.0])

    assert swipe_learning_score(model, close)["score"] > swipe_learning_score(model, far)["score"]


def test_discovery_score_includes_learned_preference_signal():
    class ProfileStub:
        city = ""
        location = {}
        budget = {}
        room_preference = "private"
        languages = []

    class UserStub:
        last_active = None

    result = score_profile(
        ProfileStub(),
        ProfileStub(),
        UserStub(),
        learned={"available": True, "score": 7},
    )

    assert result["reasons"]["learnedPreference"] == 7


def test_internal_ml_rebuild_requires_worker_token():
    client = TestClient(app)
    response = client.post("/internal/ml/profiles/00000000-0000-0000-0000-000000000000/rebuild")

    assert response.status_code == 401
