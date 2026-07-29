import uuid
from dataclasses import dataclass

from fastapi import HTTPException, UploadFile

from ..config import get_settings


ALLOWED_IMAGE_TYPES = {"image/jpeg": ".jpg", "image/png": ".png", "image/webp": ".webp"}
MAX_IMAGE_BYTES = 5 * 1024 * 1024


@dataclass
class StoredObject:
    url: str
    object_name: str


def _object_storage_client():
    settings = get_settings()
    try:
        import oci
    except ImportError as exc:
        raise HTTPException(status_code=503, detail="OCI SDK is not installed") from exc

    if settings.oci_auth_mode == "instance_principal":
        signer = oci.auth.signers.InstancePrincipalsSecurityTokenSigner()
        config = {"region": settings.oci_object_storage_region}
        return oci.object_storage.ObjectStorageClient(config, signer=signer), config

    config = oci.config.from_file(profile_name=settings.oci_config_profile)
    if settings.oci_object_storage_region:
        config["region"] = settings.oci_object_storage_region
    return oci.object_storage.ObjectStorageClient(config), config


async def upload_profile_image(user_id: uuid.UUID, file: UploadFile) -> StoredObject:
    settings = get_settings()
    if file.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(status_code=400, detail="Only JPEG, PNG, and WebP images are supported")

    body = await file.read()
    if not body:
        raise HTTPException(status_code=400, detail="Image file is empty")
    if len(body) > MAX_IMAGE_BYTES:
        raise HTTPException(status_code=413, detail="Image must be 5MB or smaller")

    if not settings.oci_object_storage_namespace or not settings.oci_object_storage_bucket:
        raise HTTPException(status_code=503, detail="OCI Object Storage is not configured")

    client, config = _object_storage_client()
    extension = ALLOWED_IMAGE_TYPES[file.content_type]
    object_name = f"{settings.oci_object_storage_prefix}/profiles/{user_id}/{uuid.uuid4()}{extension}"
    client.put_object(
        namespace_name=settings.oci_object_storage_namespace,
        bucket_name=settings.oci_object_storage_bucket,
        object_name=object_name,
        put_object_body=body,
        content_type=file.content_type,
    )

    region = config.get("region") or settings.oci_object_storage_region
    url = (
        f"https://objectstorage.{region}.oraclecloud.com/n/"
        f"{settings.oci_object_storage_namespace}/b/{settings.oci_object_storage_bucket}/o/{object_name}"
    )
    return StoredObject(url=url, object_name=object_name)


def delete_object_by_url(url: str) -> None:
    settings = get_settings()
    if not settings.oci_object_storage_namespace or not settings.oci_object_storage_bucket:
        return
    marker = f"/b/{settings.oci_object_storage_bucket}/o/"
    if marker not in url:
        return
    object_name = url.split(marker, 1)[1]
    try:
        client, _config = _object_storage_client()
        client.delete_object(settings.oci_object_storage_namespace, settings.oci_object_storage_bucket, object_name)
    except Exception:
        return
