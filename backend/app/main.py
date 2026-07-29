from fastapi import FastAPI
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.middleware.cors import CORSMiddleware

from .config import get_settings
from .middleware import InMemoryRateLimitMiddleware, RequestContextMiddleware
from .routers import admin, auth, conversations, devices, discovery, flats, health, internal_ml, location, notifications, preferences, profile, safety, swipes, users

settings = get_settings()

app = FastAPI(
    title="Flinder ML Worker" if settings.worker_only else "Flinder API",
    version="1.0.0",
    docs_url=None if settings.is_production or settings.worker_only else "/docs",
    redoc_url=None if settings.is_production or settings.worker_only else "/redoc",
    openapi_url=None if settings.is_production or settings.worker_only else "/openapi.json",
)

app.add_middleware(RequestContextMiddleware)
app.add_middleware(
    InMemoryRateLimitMiddleware,
    auth_limit_per_minute=settings.auth_rate_limit_per_minute,
)

if settings.is_production:
    app.add_middleware(TrustedHostMiddleware, allowed_hosts=settings.trusted_host_list)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list or ([] if settings.is_production else ["*"]),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(internal_ml.router)
app.include_router(health.router)

if not settings.worker_only:
    app.include_router(auth.router)
    app.include_router(profile.router)
    app.include_router(preferences.router)
    app.include_router(discovery.router)
    app.include_router(conversations.router)
    app.include_router(users.router)
    app.include_router(flats.router)
    app.include_router(devices.router)
    app.include_router(notifications.router)
    app.include_router(safety.router)
    app.include_router(swipes.router)
    app.include_router(location.router)
    app.include_router(admin.router)


@app.get("/")
def root():
    if settings.worker_only:
        return {"message": "Flinder ML worker is running"}
    return {"message": "Welcome to Flinder API!"}
