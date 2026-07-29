from typing import Any

from pydantic import BaseModel, EmailStr, Field


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)
    name: str
    phone: str | None = None
    dateOfBirth: str
    gender: str


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class GoogleAuthRequest(BaseModel):
    idToken: str


class SwipeRequest(BaseModel):
    targetUserId: str
    action: str


class ProfileRequest(BaseModel):
    bio: str
    generatedDescription: Any | None = None
    interests: list[str] = []
    location: dict[str, Any]
    budget: dict[str, Any]
    roomPreference: str
    genderPreference: str
    moveInDate: str
    leaseDuration: str
    lifestyle: dict[str, Any]
    languages: list[str] = []


class PictureRequest(BaseModel):
    url: str
    isPrimary: bool = False


class PreferencesRequest(BaseModel):
    critical: dict[str, Any]
    nonCritical: dict[str, Any] = {}
    discoverySettings: dict[str, Any] = {}
    interests: Any = []


class CreateConversationRequest(BaseModel):
    memberIds: list[str] = []
    isGroup: bool = False
    name: str | None = None


class SendMessageRequest(BaseModel):
    content: str = Field(min_length=1, max_length=5000)
    attachment: str | None = None
    attachmentType: str | None = None


class DeviceRequest(BaseModel):
    deviceId: str = Field(min_length=1)
    pushToken: str | None = None
    platform: str


class ReportUserRequest(BaseModel):
    userId: str
    reason: str = Field(min_length=2, max_length=120)
    details: str | None = Field(default=None, max_length=2000)


class ReportFlatRequest(BaseModel):
    flatId: str
    reason: str = Field(min_length=2, max_length=120)
    details: str | None = Field(default=None, max_length=2000)


class BlockUserRequest(BaseModel):
    userId: str
    reason: str | None = Field(default=None, max_length=500)


class AdminResolveRequest(BaseModel):
    status: str
    adminNotes: str | None = Field(default=None, max_length=2000)
    suspendUser: bool = False
    removeFlat: bool = False


class GeocodeRequest(BaseModel):
    query: str = Field(min_length=2, max_length=200)


class ReadMessagesRequest(BaseModel):
    messageIds: list[str] = []
