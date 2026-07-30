from datetime import date, datetime
from typing import Any

from .models import (
    Chat,
    DeviceInfo,
    Flat,
    FlatApplication,
    FlatReport,
    Message,
    Notification,
    Preference,
    Profile,
    ProfilePicture,
    User,
    UserBlock,
    UserReport,
)


def iso(value: date | datetime | None) -> str | None:
    return value.isoformat() if value else None


def user_to_client(user: User) -> dict[str, Any]:
    return {
        "id": str(user.id),
        "email": user.email,
        "name": user.name,
        "profileCompleted": bool(user.profile_completed),
        "profileQuestionnaireSkipped": bool(getattr(user, "profile_questionnaire_skipped_at", None)),
        "profileCompletionScore": getattr(user.profile, "completion_score", 0) if getattr(user, "profile", None) else 0,
        "onlineStatus": user.online_status,
        "createdAt": iso(user.created_at),
        "verificationStatus": user.verification_status,
        "role": getattr(user, "role", "user"),
    }


def picture_to_client(picture: ProfilePicture) -> dict[str, Any]:
    return {
        "id": str(picture.id),
        "url": picture.url,
        "isPrimary": picture.is_primary,
        "uploadedAt": iso(picture.uploaded_at),
    }


def profile_to_client(profile: Profile, user: User | None = None) -> dict[str, Any]:
    generated = profile.generated_description
    if isinstance(generated, dict):
        generated = ", ".join(str(value) for value in generated.values() if value)

    data = {
        "userId": str(profile.user_id),
        "bio": profile.bio,
        "generatedDescription": generated,
        "interests": profile.interests or [],
        "profilePictures": [picture_to_client(picture) for picture in profile.pictures],
        "location": profile.location,
        "budget": profile.budget,
        "roomPreference": profile.room_preference,
        "genderPreference": profile.gender_preference,
        "moveInDate": profile.move_in_date,
        "leaseDuration": profile.lease_duration,
        "lifestyle": profile.lifestyle,
        "languages": profile.languages or [],
        "onboardingStep": getattr(profile, "onboarding_step", "basic"),
        "completionScore": getattr(profile, "completion_score", 0),
        "coordinates": {
            "latitude": getattr(profile, "latitude", None),
            "longitude": getattr(profile, "longitude", None),
        },
        "city": getattr(profile, "city", None),
        "country": getattr(profile, "country", None),
    }
    if user:
        data.update(
            {
                "id": str(user.id),
                "name": user.name,
                "email": user.email,
                "phone": user.phone,
                "date_of_birth": iso(user.date_of_birth),
                "gender": user.gender,
                "profile_completed": user.profile_completed,
                "last_active": iso(user.last_active),
                "online_status": user.online_status,
            }
        )
    return data


def preference_to_client(preference: Preference) -> dict[str, Any]:
    return {
        "id": str(preference.id),
        "userId": str(preference.user_id),
        "critical": preference.critical,
        "nonCritical": preference.non_critical,
        "discoverySettings": preference.discovery_settings,
        "interests": preference.interests,
    }


def flat_to_client(flat: Flat) -> dict[str, Any]:
    return {
        "id": str(flat.id),
        "title": flat.title,
        "address": flat.address,
        "city": flat.city,
        "rent": flat.rent,
        "num_rooms": flat.num_rooms,
        "numRooms": flat.num_rooms,
        "amenities": flat.amenities or [],
        "description": flat.description,
        "image_url": flat.image_url,
        "imageUrl": flat.image_url,
        "created_at": iso(flat.created_at),
        "latitude": getattr(flat, "latitude", None),
        "longitude": getattr(flat, "longitude", None),
        "status": getattr(flat, "status", "active"),
        "ownerId": str(flat.owner_id) if getattr(flat, "owner_id", None) else None,
    }


def application_to_client(application: FlatApplication) -> dict[str, Any]:
    return {
        "id": str(application.id),
        "flat_id": str(application.flat_id),
        "flatId": str(application.flat_id),
        "group_chat_id": str(application.group_chat_id),
        "groupChatId": str(application.group_chat_id),
        "user_id": str(application.user_id),
        "userId": str(application.user_id),
        "status": application.status,
        "created_at": iso(application.created_at),
        "createdAt": iso(application.created_at),
    }


def message_to_client(message: Message) -> dict[str, Any]:
    return {
        "id": str(message.id),
        "chat_id": str(message.chat_id),
        "sender_id": str(message.sender_id),
        "content": message.content,
        "attachment": message.attachment,
        "attachment_type": message.attachment_type,
        "sent_at": iso(message.sent_at),
        "is_read": message.is_read,
        "is_deleted": message.is_deleted,
        "read_at": iso(getattr(message, "read_at", None)),
    }


def chat_to_client(chat: Chat, last_message: Message | None = None) -> dict[str, Any]:
    return {
        "id": str(chat.id),
        "is_group": chat.is_group,
        "name": chat.name,
        "participants": [
            {
                "id": str(member.user.id),
                "name": member.user.name,
                "profile_pic": None,
            }
            for member in chat.members
        ],
        "last_activity": iso(last_message.sent_at if last_message else chat.updated_at),
        "last_message": last_message.content if last_message else None,
        "last_message_time": iso(last_message.sent_at if last_message else None),
        "unread_count": 0,
    }


def device_to_client(device: DeviceInfo) -> dict[str, Any]:
    return {
        "id": str(device.id),
        "deviceId": device.device_id,
        "platform": device.platform,
        "hasPushToken": bool(device.push_token),
        "createdAt": iso(device.created_at),
        "updatedAt": iso(device.updated_at),
    }


def notification_to_client(notification: Notification) -> dict[str, Any]:
    return {
        "id": str(notification.id),
        "type": notification.type,
        "title": notification.title,
        "body": notification.body,
        "data": notification.data or {},
        "isRead": notification.is_read,
        "createdAt": iso(notification.created_at),
        "expireAt": iso(notification.expire_at),
    }


def user_report_to_client(report: UserReport) -> dict[str, Any]:
    return {
        "id": str(report.id),
        "reporterId": str(report.reporter_id),
        "reportedUserId": str(report.reported_user_id),
        "reason": report.reason,
        "details": report.details,
        "status": report.status,
        "adminNotes": report.admin_notes,
        "createdAt": iso(report.created_at),
        "resolvedAt": iso(report.resolved_at),
    }


def flat_report_to_client(report: FlatReport) -> dict[str, Any]:
    return {
        "id": str(report.id),
        "reporterId": str(report.reporter_id),
        "flatId": str(report.flat_id),
        "reason": report.reason,
        "details": report.details,
        "status": report.status,
        "adminNotes": report.admin_notes,
        "createdAt": iso(report.created_at),
        "resolvedAt": iso(report.resolved_at),
    }


def block_to_client(block: UserBlock) -> dict[str, Any]:
    return {
        "id": str(block.id),
        "blockerId": str(block.blocker_id),
        "blockedId": str(block.blocked_id),
        "reason": block.reason,
        "createdAt": iso(block.created_at),
    }
