from __future__ import annotations

import io
from abc import ABC, abstractmethod
from datetime import datetime
from typing import Any

import firebase_admin
from firebase_admin import credentials, firestore
from google.cloud import storage as gcs_storage
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseUpload
from google.oauth2 import service_account

try:
    from .config import get_settings
    from .models import utc_now
    from .storage import load_db, save_db
except ImportError:
    from config import get_settings  # type: ignore
    from models import utc_now  # type: ignore
    from storage import load_db, save_db  # type: ignore


class Repository(ABC):
    @abstractmethod
    def list_users(self) -> list[dict[str, Any]]: ...

    @abstractmethod
    def get_user(self, user_id: str) -> dict[str, Any] | None: ...

    @abstractmethod
    def upsert_user(self, user: dict[str, Any]) -> dict[str, Any]: ...

    @abstractmethod
    def delete_user(self, user_id: str) -> dict[str, Any] | None: ...

    @abstractmethod
    def list_questions(self) -> list[dict[str, Any]]: ...

    @abstractmethod
    def create_question(self, question: dict[str, Any]) -> dict[str, Any]: ...

    @abstractmethod
    def update_question(self, question_id: str, updates: dict[str, Any]) -> dict[str, Any] | None: ...

    @abstractmethod
    def delete_question(self, question_id: str) -> dict[str, Any] | None: ...

    @abstractmethod
    def create_attachment(self, attachment: dict[str, Any]) -> dict[str, Any]: ...

    @abstractmethod
    def list_attachments(self) -> list[dict[str, Any]]: ...

    @abstractmethod
    def update_attachment(self, attachment_id: str, updates: dict[str, Any]) -> dict[str, Any] | None: ...

    @abstractmethod
    def add_response(self, question_id: str, response: dict[str, Any]) -> dict[str, Any] | None: ...

    @abstractmethod
    def add_thread_message(self, question_id: str, message: dict[str, Any], *, reopen: bool) -> dict[str, Any] | None: ...

    @abstractmethod
    def list_education(self) -> list[dict[str, Any]]: ...

    @abstractmethod
    def seed_education(self, items: list[dict[str, Any]]) -> None: ...

    @abstractmethod
    def seed_questions(self, items: list[dict[str, Any]]) -> None: ...

    @abstractmethod
    def create_payment(self, payment: dict[str, Any]) -> dict[str, Any]: ...

    @abstractmethod
    def list_title_templates(self) -> list[dict[str, Any]]: ...

    @abstractmethod
    def create_title_template(self, template: dict[str, Any]) -> dict[str, Any]: ...

    @abstractmethod
    def list_blog_articles(self) -> list[dict[str, Any]]: ...

    @abstractmethod
    def create_blog_article(self, article: dict[str, Any]) -> dict[str, Any]: ...

    @abstractmethod
    def list_notifications(self) -> list[dict[str, Any]]: ...

    @abstractmethod
    def create_notification(self, notification: dict[str, Any]) -> dict[str, Any]: ...

    @abstractmethod
    def list_otp_requests(self) -> list[dict[str, Any]]: ...

    @abstractmethod
    def create_otp_request(self, otp_request: dict[str, Any]) -> dict[str, Any]: ...

    @abstractmethod
    def update_otp_request(self, otp_request_id: str, updates: dict[str, Any]) -> dict[str, Any] | None: ...

    @abstractmethod
    def get_notification_settings(self) -> dict[str, Any] | None: ...

    @abstractmethod
    def upsert_notification_settings(self, settings: dict[str, Any]) -> dict[str, Any]: ...

    @abstractmethod
    def moderate_thread_message(
        self,
        question_id: str,
        message_id: str,
        moderation_state: str,
    ) -> dict[str, Any] | None: ...

    @abstractmethod
    def list_ad_campaigns(self) -> list[dict[str, Any]]: ...

    @abstractmethod
    def create_ad_campaign(self, campaign: dict[str, Any]) -> dict[str, Any]: ...

    @abstractmethod
    def update_ad_campaign(
        self,
        campaign_id: str,
        updates: dict[str, Any],
    ) -> dict[str, Any] | None: ...

    @abstractmethod
    def get_app_settings(self) -> dict[str, Any] | None: ...

    @abstractmethod
    def upsert_app_settings(self, settings: dict[str, Any]) -> dict[str, Any]: ...


class LocalJsonRepository(Repository):
    def _db(self) -> dict[str, Any]:
        return load_db()

    def list_users(self) -> list[dict[str, Any]]:
        return self._db()["users"]

    def get_user(self, user_id: str) -> dict[str, Any] | None:
        return next((user for user in self._db()["users"] if user["id"] == user_id), None)

    def upsert_user(self, user: dict[str, Any]) -> dict[str, Any]:
        db = self._db()
        users = db["users"]
        for index, existing in enumerate(users):
            if existing["id"] == user["id"] or existing["email"].lower() == user["email"].lower():
                if existing["id"] != user["id"]:
                    self._remap_user_references(db, existing["id"], user["id"])
                users[index] = user
                save_db(db)
                return user
        users.append(user)
        save_db(db)
        return user

    def delete_user(self, user_id: str) -> dict[str, Any] | None:
        db = self._db()
        users = db["users"]
        for index, existing in enumerate(users):
            if existing["id"] == user_id:
                removed = users.pop(index)
                for question in db["questions"]:
                    if question.get("author_id") == user_id:
                        question["status"] = "deleted"
                        question["updated_at"] = utc_now().isoformat()
                    for message in question.get("thread_messages", []):
                        if message.get("actor_id") == user_id:
                            message["moderation_state"] = "hidden"
                save_db(db)
                return removed
        return None

    def _remap_user_references(self, db: dict[str, Any], old_id: str, new_id: str) -> None:
        for question in db["questions"]:
            if question.get("author_id") == old_id:
                question["author_id"] = new_id
            if question.get("target_doctor_id") == old_id:
                question["target_doctor_id"] = new_id
            for response in question.get("responses", []):
                if response.get("doctor_id") == old_id:
                    response["doctor_id"] = new_id
            for message in question.get("thread_messages", []):
                if message.get("actor_id") == old_id:
                    message["actor_id"] = new_id

    def list_questions(self) -> list[dict[str, Any]]:
        return self._db()["questions"]

    def create_question(self, question: dict[str, Any]) -> dict[str, Any]:
        db = self._db()
        db["questions"].append(question)
        save_db(db)
        return question

    def update_question(self, question_id: str, updates: dict[str, Any]) -> dict[str, Any] | None:
        db = self._db()
        for question in db["questions"]:
            if question["id"] == question_id:
                question.update(updates)
                save_db(db)
                return question
        return None

    def delete_question(self, question_id: str) -> dict[str, Any] | None:
        db = self._db()
        for index, question in enumerate(db["questions"]):
            if question["id"] == question_id:
                removed = db["questions"].pop(index)
                save_db(db)
                return removed
        return None

    def create_attachment(self, attachment: dict[str, Any]) -> dict[str, Any]:
        db = self._db()
        db["attachments"].append(attachment)
        save_db(db)
        return attachment

    def list_attachments(self) -> list[dict[str, Any]]:
        return self._db()["attachments"]

    def update_attachment(self, attachment_id: str, updates: dict[str, Any]) -> dict[str, Any] | None:
        db = self._db()
        for attachment in db["attachments"]:
            if attachment["id"] == attachment_id:
                attachment.update(updates)
                save_db(db)
                return attachment
        return None

    def add_response(self, question_id: str, response: dict[str, Any]) -> dict[str, Any] | None:
        db = self._db()
        for question in db["questions"]:
            if question["id"] == question_id:
                question.setdefault("responses", []).append(response)
                question["status"] = "answered"
                question["updated_at"] = response["created_at"]
                save_db(db)
                return response
        return None

    def add_thread_message(self, question_id: str, message: dict[str, Any], *, reopen: bool) -> dict[str, Any] | None:
        db = self._db()
        for question in db["questions"]:
            if question["id"] == question_id:
                question.setdefault("thread_messages", []).append(message)
                question["status"] = "open" if reopen else question.get("status", "open")
                question["updated_at"] = message["created_at"]
                save_db(db)
                return message
        return None

    def list_education(self) -> list[dict[str, Any]]:
        return self._db()["education"]

    def seed_education(self, items: list[dict[str, Any]]) -> None:
        db = self._db()
        if not db["education"]:
            db["education"] = items
            save_db(db)

    def seed_questions(self, items: list[dict[str, Any]]) -> None:
        db = self._db()
        if not db["questions"]:
            db["questions"] = items
            save_db(db)

    def create_payment(self, payment: dict[str, Any]) -> dict[str, Any]:
        db = self._db()
        db["payments"].append(payment)
        save_db(db)
        return payment

    def list_title_templates(self) -> list[dict[str, Any]]:
        return self._db()["title_templates"]

    def create_title_template(self, template: dict[str, Any]) -> dict[str, Any]:
        db = self._db()
        db["title_templates"].append(template)
        save_db(db)
        return template

    def list_blog_articles(self) -> list[dict[str, Any]]:
        return self._db()["blog_articles"]

    def create_blog_article(self, article: dict[str, Any]) -> dict[str, Any]:
        db = self._db()
        db["blog_articles"].append(article)
        save_db(db)
        return article

    def list_notifications(self) -> list[dict[str, Any]]:
        return self._db()["notifications"]

    def create_notification(self, notification: dict[str, Any]) -> dict[str, Any]:
        db = self._db()
        db["notifications"].append(notification)
        save_db(db)
        return notification

    def list_otp_requests(self) -> list[dict[str, Any]]:
        return self._db()["otp_requests"]

    def create_otp_request(self, otp_request: dict[str, Any]) -> dict[str, Any]:
        db = self._db()
        db["otp_requests"].append(otp_request)
        save_db(db)
        return otp_request

    def update_otp_request(self, otp_request_id: str, updates: dict[str, Any]) -> dict[str, Any] | None:
        db = self._db()
        for otp_request in db["otp_requests"]:
            if otp_request["id"] == otp_request_id:
                otp_request.update(updates)
                save_db(db)
                return otp_request
        return None

    def get_notification_settings(self) -> dict[str, Any] | None:
        settings = self._db().get("notification_settings")
        return settings if settings else None

    def upsert_notification_settings(self, settings: dict[str, Any]) -> dict[str, Any]:
        db = self._db()
        db["notification_settings"] = settings
        save_db(db)
        return settings

    def moderate_thread_message(
        self,
        question_id: str,
        message_id: str,
        moderation_state: str,
    ) -> dict[str, Any] | None:
        db = self._db()
        for question in db["questions"]:
            if question["id"] != question_id:
                continue
            for message in question.get("thread_messages", []):
                if message.get("id") == message_id:
                    message["moderation_state"] = moderation_state
                    save_db(db)
                    return message
        return None

    def list_ad_campaigns(self) -> list[dict[str, Any]]:
        return self._db()["ad_campaigns"]

    def create_ad_campaign(self, campaign: dict[str, Any]) -> dict[str, Any]:
        db = self._db()
        db["ad_campaigns"].append(campaign)
        save_db(db)
        return campaign

    def update_ad_campaign(
        self,
        campaign_id: str,
        updates: dict[str, Any],
    ) -> dict[str, Any] | None:
        db = self._db()
        for campaign in db["ad_campaigns"]:
            if campaign["id"] == campaign_id:
                campaign.update(updates)
                save_db(db)
                return campaign
        return None

    def get_app_settings(self) -> dict[str, Any] | None:
        settings = self._db().get("app_settings")
        return settings if settings else None

    def upsert_app_settings(self, settings: dict[str, Any]) -> dict[str, Any]:
        db = self._db()
        db["app_settings"] = settings
        save_db(db)
        return settings


class FirestoreRepository(Repository):
    def __init__(self) -> None:
        settings = get_settings()
        if not settings.google_service_account_json:
            raise RuntimeError("GOOGLE_SERVICE_ACCOUNT_JSON is required for Firestore mode.")
        if not firebase_admin._apps:
            cred = credentials.Certificate(settings.google_service_account_json)
            firebase_admin.initialize_app(cred, {"projectId": settings.firebase_project_id or None})
        self._db = firestore.client()

    def _collection(self, name: str):
        return self._db.collection(name)

    def list_users(self) -> list[dict[str, Any]]:
        return [self._decode(doc.to_dict()) for doc in self._collection("users").stream()]

    def get_user(self, user_id: str) -> dict[str, Any] | None:
        snap = self._collection("users").document(user_id).get()
        if not snap.exists:
            return None
        return self._decode(snap.to_dict())

    def upsert_user(self, user: dict[str, Any]) -> dict[str, Any]:
        matches = list(
            self._collection("users")
            .where("email", "==", user["email"])
            .stream()
        )
        for match in matches:
            if match.id != user["id"]:
                self._remap_user_references(match.id, user["id"])
                match.reference.delete()
        self._collection("users").document(user["id"]).set(user)
        return user

    def delete_user(self, user_id: str) -> dict[str, Any] | None:
        snap = self._collection("users").document(user_id).get()
        if not snap.exists:
            return None
        removed = self._decode(snap.to_dict())
        for question_snap in self._collection("questions").stream():
            question = self._decode(question_snap.to_dict())
            changed = False
            if question.get("author_id") == user_id:
                question["status"] = "deleted"
                question["updated_at"] = utc_now().isoformat()
                changed = True
            for message in question.get("thread_messages", []):
                if message.get("actor_id") == user_id:
                    message["moderation_state"] = "hidden"
                    changed = True
            if changed:
                question_snap.reference.set(question)
        snap.reference.delete()
        return removed

    def _remap_user_references(self, old_id: str, new_id: str) -> None:
        for snap in self._collection("questions").stream():
            question = self._decode(snap.to_dict())
            changed = False
            if question.get("author_id") == old_id:
                question["author_id"] = new_id
                changed = True
            if question.get("target_doctor_id") == old_id:
                question["target_doctor_id"] = new_id
                changed = True
            for response in question.get("responses", []):
                if response.get("doctor_id") == old_id:
                    response["doctor_id"] = new_id
                    changed = True
            for message in question.get("thread_messages", []):
                if message.get("actor_id") == old_id:
                    message["actor_id"] = new_id
                    changed = True
            if changed:
                self._collection("questions").document(question["id"]).set(question)

    def list_questions(self) -> list[dict[str, Any]]:
        return [self._decode(doc.to_dict()) for doc in self._collection("questions").stream()]

    def create_question(self, question: dict[str, Any]) -> dict[str, Any]:
        self._collection("questions").document(question["id"]).set(question)
        return question

    def update_question(self, question_id: str, updates: dict[str, Any]) -> dict[str, Any] | None:
        ref = self._collection("questions").document(question_id)
        snap = ref.get()
        if not snap.exists:
            return None
        current = self._decode(snap.to_dict())
        current.update(updates)
        ref.set(current)
        return current

    def delete_question(self, question_id: str) -> dict[str, Any] | None:
        ref = self._collection("questions").document(question_id)
        snap = ref.get()
        if not snap.exists:
            return None
        current = self._decode(snap.to_dict())
        ref.delete()
        return current

    def create_attachment(self, attachment: dict[str, Any]) -> dict[str, Any]:
        self._collection("attachments").document(attachment["id"]).set(attachment)
        return attachment

    def list_attachments(self) -> list[dict[str, Any]]:
        return [self._decode(doc.to_dict()) for doc in self._collection("attachments").stream()]

    def update_attachment(self, attachment_id: str, updates: dict[str, Any]) -> dict[str, Any] | None:
        ref = self._collection("attachments").document(attachment_id)
        snap = ref.get()
        if not snap.exists:
            return None
        current = self._decode(snap.to_dict())
        current.update(updates)
        ref.set(current)
        return current

    def add_response(self, question_id: str, response: dict[str, Any]) -> dict[str, Any] | None:
        ref = self._collection("questions").document(question_id)
        snap = ref.get()
        if not snap.exists:
            return None
        question = self._decode(snap.to_dict())
        question.setdefault("responses", []).append(response)
        question["status"] = "answered"
        question["updated_at"] = response["created_at"]
        ref.set(question)
        return response

    def add_thread_message(self, question_id: str, message: dict[str, Any], *, reopen: bool) -> dict[str, Any] | None:
        ref = self._collection("questions").document(question_id)
        snap = ref.get()
        if not snap.exists:
            return None
        question = self._decode(snap.to_dict())
        question.setdefault("thread_messages", []).append(message)
        if reopen:
            question["status"] = "open"
        question["updated_at"] = message["created_at"]
        ref.set(question)
        return message

    def list_education(self) -> list[dict[str, Any]]:
        return [self._decode(doc.to_dict()) for doc in self._collection("education_library").stream()]

    def seed_education(self, items: list[dict[str, Any]]) -> None:
        if self.list_education():
            return
        batch = self._db.batch()
        for item in items:
            batch.set(self._collection("education_library").document(item["id"]), item)
        batch.commit()

    def seed_questions(self, items: list[dict[str, Any]]) -> None:
        if self.list_questions():
            return
        batch = self._db.batch()
        for item in items:
            batch.set(self._collection("questions").document(item["id"]), item)
        batch.commit()

    def create_payment(self, payment: dict[str, Any]) -> dict[str, Any]:
        self._collection("payments").document(payment["payment_id"]).set(payment)
        return payment

    def list_title_templates(self) -> list[dict[str, Any]]:
        return [self._decode(doc.to_dict()) for doc in self._collection("title_templates").stream()]

    def create_title_template(self, template: dict[str, Any]) -> dict[str, Any]:
        self._collection("title_templates").document(template["id"]).set(template)
        return template

    def list_blog_articles(self) -> list[dict[str, Any]]:
        return [self._decode(doc.to_dict()) for doc in self._collection("blog_articles").stream()]

    def create_blog_article(self, article: dict[str, Any]) -> dict[str, Any]:
        self._collection("blog_articles").document(article["id"]).set(article)
        return article

    def list_notifications(self) -> list[dict[str, Any]]:
        return [self._decode(doc.to_dict()) for doc in self._collection("notifications").stream()]

    def create_notification(self, notification: dict[str, Any]) -> dict[str, Any]:
        self._collection("notifications").document(notification["id"]).set(notification)
        return notification

    def list_otp_requests(self) -> list[dict[str, Any]]:
        return [self._decode(doc.to_dict()) for doc in self._collection("otp_requests").stream()]

    def create_otp_request(self, otp_request: dict[str, Any]) -> dict[str, Any]:
        self._collection("otp_requests").document(otp_request["id"]).set(otp_request)
        return otp_request

    def update_otp_request(self, otp_request_id: str, updates: dict[str, Any]) -> dict[str, Any] | None:
        ref = self._collection("otp_requests").document(otp_request_id)
        snap = ref.get()
        if not snap.exists:
            return None
        current = self._decode(snap.to_dict())
        current.update(updates)
        ref.set(current)
        return current

    def get_notification_settings(self) -> dict[str, Any] | None:
        snap = self._collection("app_config").document("notification_settings").get()
        if not snap.exists:
            return None
        return self._decode(snap.to_dict())

    def upsert_notification_settings(self, settings: dict[str, Any]) -> dict[str, Any]:
        self._collection("app_config").document("notification_settings").set(settings)
        return settings

    def moderate_thread_message(
        self,
        question_id: str,
        message_id: str,
        moderation_state: str,
    ) -> dict[str, Any] | None:
        ref = self._collection("questions").document(question_id)
        snap = ref.get()
        if not snap.exists:
            return None
        question = self._decode(snap.to_dict())
        for message in question.get("thread_messages", []):
            if message.get("id") == message_id:
                message["moderation_state"] = moderation_state
                ref.set(question)
                return message
        return None

    def list_ad_campaigns(self) -> list[dict[str, Any]]:
        return [self._decode(doc.to_dict()) for doc in self._collection("ad_campaigns").stream()]

    def create_ad_campaign(self, campaign: dict[str, Any]) -> dict[str, Any]:
        self._collection("ad_campaigns").document(campaign["id"]).set(campaign)
        return campaign

    def update_ad_campaign(
        self,
        campaign_id: str,
        updates: dict[str, Any],
    ) -> dict[str, Any] | None:
        ref = self._collection("ad_campaigns").document(campaign_id)
        snap = ref.get()
        if not snap.exists:
            return None
        current = self._decode(snap.to_dict())
        current.update(updates)
        ref.set(current)
        return current

    def get_app_settings(self) -> dict[str, Any] | None:
        snap = self._collection("app_config").document("app_settings").get()
        if not snap.exists:
            return None
        return self._decode(snap.to_dict())

    def upsert_app_settings(self, settings: dict[str, Any]) -> dict[str, Any]:
        self._collection("app_config").document("app_settings").set(settings)
        return settings

    def _decode(self, value: Any) -> Any:
        if isinstance(value, datetime):
            return value.isoformat()
        if isinstance(value, dict):
            return {key: self._decode(inner) for key, inner in value.items()}
        if isinstance(value, list):
            return [self._decode(item) for item in value]
        return value


class FileStorageProvider(ABC):
    @abstractmethod
    def upload_bytes(self, *, owner_id: str, file_name: str, mime_type: str, content: bytes) -> dict[str, str]: ...

    @abstractmethod
    def revoke(self, *, storage_id: str) -> None: ...


class LocalFileStorageProvider(FileStorageProvider):
    def upload_bytes(self, *, owner_id: str, file_name: str, mime_type: str, content: bytes) -> dict[str, str]:
        safe_name = file_name.replace("/", "_").replace("\\", "_")
        return {
            "storage_id": f"local-{owner_id}-{safe_name}",
            "storage_provider": "local_stub",
            "temporary_url": f"https://medicohub.local/files/{safe_name}",
            "storage_path": safe_name,
        }

    def revoke(self, *, storage_id: str) -> None:
        return None


class GoogleDriveStorageProvider(FileStorageProvider):
    def __init__(self) -> None:
        settings = get_settings()
        if not settings.google_service_account_json or not settings.google_drive_parent_folder_id:
            raise RuntimeError("Google Drive storage requires service account JSON and parent folder id.")
        scoped = service_account.Credentials.from_service_account_file(
            settings.google_service_account_json,
            scopes=["https://www.googleapis.com/auth/drive"],
        )
        self._folder_id = settings.google_drive_parent_folder_id
        self._service = build("drive", "v3", credentials=scoped, cache_discovery=False)

    def upload_bytes(self, *, owner_id: str, file_name: str, mime_type: str, content: bytes) -> dict[str, str]:
        body = {
            "name": file_name,
            "parents": [self._folder_id],
            "description": f"MedicoHub upload for {owner_id}",
        }
        media = MediaIoBaseUpload(io.BytesIO(content), mimetype=mime_type, resumable=False)
        created = (
            self._service.files()
            .create(
                body=body,
                media_body=media,
                fields="id,webViewLink,webContentLink",
                supportsAllDrives=True,
            )
            .execute()
        )
        self._service.permissions().create(
            fileId=created["id"],
            body={"role": "reader", "type": "anyone"},
            supportsAllDrives=True,
        ).execute()
        return {
            "storage_id": created["id"],
            "storage_provider": "google_drive",
            "temporary_url": created.get("webContentLink") or created.get("webViewLink") or "",
            "storage_path": created["id"],
        }

    def revoke(self, *, storage_id: str) -> None:
        self._service.files().delete(
            fileId=storage_id,
            supportsAllDrives=True,
        ).execute()


class FirebaseStorageProvider(FileStorageProvider):
    def __init__(self) -> None:
        settings = get_settings()
        if not settings.google_service_account_json:
            raise RuntimeError("Firebase Storage requires service account JSON.")
        bucket_name = settings.firebase_storage_bucket or f"{settings.firebase_project_id}.firebasestorage.app"
        creds = service_account.Credentials.from_service_account_file(
            settings.google_service_account_json,
        )
        self._client = gcs_storage.Client(
            project=settings.firebase_project_id,
            credentials=creds,
        )
        self._bucket = self._client.bucket(bucket_name)

    def upload_bytes(self, *, owner_id: str, file_name: str, mime_type: str, content: bytes) -> dict[str, str]:
        timestamp = datetime.utcnow().strftime("%Y%m%d%H%M%S")
        object_name = f"medicohub_uploads/{owner_id}/{timestamp}_{file_name}"
        blob = self._bucket.blob(object_name)
        blob.upload_from_string(content, content_type=mime_type)
        signed_url = blob.generate_signed_url(
            version="v4",
            expiration=604800,
            method="GET",
        )
        return {
            "storage_id": object_name,
            "storage_provider": "firebase_storage",
            "temporary_url": signed_url,
            "storage_path": object_name,
        }

    def revoke(self, *, storage_id: str) -> None:
        blob = self._bucket.blob(storage_id)
        blob.delete()


def get_repository() -> Repository:
    settings = get_settings()
    if settings.enable_firestore:
        try:
            return FirestoreRepository()
        except Exception:
            return LocalJsonRepository()
    return LocalJsonRepository()


def get_file_storage_provider() -> FileStorageProvider:
    settings = get_settings()
    if settings.enable_firebase_storage:
        try:
            return FirebaseStorageProvider()
        except Exception:
            return LocalFileStorageProvider()
    if settings.enable_google_drive:
        try:
            return GoogleDriveStorageProvider()
        except Exception:
            return LocalFileStorageProvider()
    return LocalFileStorageProvider()
