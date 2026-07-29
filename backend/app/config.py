from functools import lru_cache

from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_env: str = "development"
    database_url: str
    jwt_secret: str
    jwt_expires_minutes: int = 60 * 24 * 7
    cors_origins: str = ""
    google_oauth_client_id: str = ""
    trusted_hosts: str = "localhost,127.0.0.1"
    auth_rate_limit_per_minute: int = 20
    public_base_url: str = ""
    oci_object_storage_namespace: str = ""
    oci_object_storage_bucket: str = ""
    oci_object_storage_region: str = ""
    oci_object_storage_prefix: str = "flinder"
    oci_auth_mode: str = "config_file"
    oci_config_profile: str = "DEFAULT"
    firebase_credentials_path: str = ""
    nominatim_user_agent: str = "Flinder/1.0"
    admin_emails: str = ""

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    @property
    def cors_origin_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]

    @property
    def trusted_host_list(self) -> list[str]:
        return [host.strip() for host in self.trusted_hosts.split(",") if host.strip()]

    @property
    def admin_email_set(self) -> set[str]:
        return {email.strip().lower() for email in self.admin_emails.split(",") if email.strip()}

    @property
    def is_production(self) -> bool:
        return self.app_env.lower() == "production"

    @model_validator(mode="after")
    def validate_production_settings(self):
        if self.is_production:
            if not self.cors_origin_list:
                raise ValueError("CORS_ORIGINS must be set in production")
            if "*" in self.cors_origin_list:
                raise ValueError("Wildcard CORS is not allowed in production")
            if len(self.jwt_secret) < 32 or self.jwt_secret == "change-me":
                raise ValueError("JWT_SECRET must be at least 32 characters in production")
            if not self.google_oauth_client_id:
                raise ValueError("GOOGLE_OAUTH_CLIENT_ID must be set in production")
        return self


@lru_cache
def get_settings() -> Settings:
    return Settings()
