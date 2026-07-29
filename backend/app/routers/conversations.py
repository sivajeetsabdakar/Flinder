import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect
from sqlalchemy import and_, or_, select
from sqlalchemy.orm import Session, selectinload

from ..database import SessionLocal, get_db
from ..deps import get_current_user
from ..models import Chat, ChatMember, Message, User, UserBlock
from ..schemas import CreateConversationRequest, ReadMessagesRequest, SendMessageRequest
from ..security import decode_access_token
from ..serializers import chat_to_client, message_to_client
from ..services.notifications import create_notification
from ..services.realtime import manager

router = APIRouter(prefix="/api/conversations", tags=["conversations"])


def parse_uuid(value: str, field: str = "id") -> uuid.UUID:
    try:
        return uuid.UUID(value)
    except ValueError:
        raise HTTPException(status_code=400, detail=f"Invalid {field}")


def require_chat_member(chat_id: uuid.UUID, user_id: uuid.UUID, db: Session) -> Chat:
    chat = db.scalar(
        select(Chat)
        .options(selectinload(Chat.members).selectinload(ChatMember.user))
        .where(Chat.id == chat_id)
    )
    if not chat:
        raise HTTPException(status_code=404, detail="Conversation not found")

    is_member = any(member.user_id == user_id for member in chat.members)
    if not is_member:
        raise HTTPException(status_code=403, detail="You are not a member of this conversation")

    return chat


def get_last_message(chat_id: uuid.UUID, db: Session) -> Message | None:
    return db.scalar(
        select(Message)
        .where(Message.chat_id == chat_id, Message.is_deleted.is_(False))
        .order_by(Message.sent_at.desc())
        .limit(1)
    )


@router.get("")
def list_conversations(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    chats = db.scalars(
        select(Chat)
        .join(ChatMember, ChatMember.chat_id == Chat.id)
        .options(selectinload(Chat.members).selectinload(ChatMember.user))
        .where(ChatMember.user_id == current_user.id)
        .order_by(Chat.updated_at.desc())
    ).all()

    conversations = [
        chat_to_client(chat, get_last_message(chat.id, db))
        for chat in chats
    ]
    return {"conversations": conversations}


@router.post("", status_code=201)
def create_conversation(
    payload: CreateConversationRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    member_ids = {parse_uuid(member_id, "memberId") for member_id in payload.memberIds}
    member_ids.add(current_user.id)

    if not payload.isGroup and len(member_ids) != 2:
        raise HTTPException(status_code=400, detail="One-on-one conversations require exactly two members")

    existing_users = set(
        db.scalars(select(User.id).where(User.id.in_(member_ids))).all()
    )
    missing_users = member_ids - existing_users
    if missing_users:
        raise HTTPException(status_code=400, detail="One or more members do not exist")

    if not payload.isGroup:
        other_user_id = next(member_id for member_id in member_ids if member_id != current_user.id)
        if db.scalar(select(UserBlock).where(or_(
            and_(UserBlock.blocker_id == current_user.id, UserBlock.blocked_id == other_user_id),
            and_(UserBlock.blocker_id == other_user_id, UserBlock.blocked_id == current_user.id),
        ))):
            raise HTTPException(status_code=403, detail="You cannot start a conversation with this user")
        current_user_chats = select(ChatMember.chat_id).where(ChatMember.user_id == current_user.id)
        existing_chat = db.scalar(
            select(Chat)
            .join(ChatMember, ChatMember.chat_id == Chat.id)
            .options(selectinload(Chat.members).selectinload(ChatMember.user))
            .where(Chat.is_group.is_(False))
            .where(Chat.id.in_(current_user_chats))
            .where(ChatMember.user_id == other_user_id)
            .limit(1)
        )
        if existing_chat:
            return {"conversation": chat_to_client(existing_chat, get_last_message(existing_chat.id, db))}

    chat = Chat(
        name=payload.name if payload.isGroup else payload.name,
        is_group=payload.isGroup,
        created_by=current_user.id,
        updated_at=datetime.now(timezone.utc),
    )
    db.add(chat)
    db.flush()

    for member_id in member_ids:
        db.add(ChatMember(chat_id=chat.id, user_id=member_id))

    db.commit()
    db.refresh(chat)
    chat = require_chat_member(chat.id, current_user.id, db)
    return {"conversation": chat_to_client(chat)}


@router.get("/{conversation_id}/messages")
def list_messages(
    conversation_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    chat_id = parse_uuid(conversation_id, "conversation_id")
    require_chat_member(chat_id, current_user.id, db)

    messages = db.scalars(
        select(Message)
        .where(Message.chat_id == chat_id, Message.is_deleted.is_(False))
        .order_by(Message.sent_at.asc())
        .limit(100)
    ).all()
    return {"messages": [message_to_client(message) for message in messages]}


@router.post("/{conversation_id}/messages", status_code=201)
async def send_message(
    conversation_id: str,
    payload: SendMessageRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    chat_id = parse_uuid(conversation_id, "conversation_id")
    chat = require_chat_member(chat_id, current_user.id, db)

    message = Message(
        chat_id=chat_id,
        sender_id=current_user.id,
        content=payload.content,
        attachment=payload.attachment,
        attachment_type=payload.attachmentType,
    )
    chat.updated_at = datetime.now(timezone.utc)
    db.add(message)
    for member in chat.members:
        if member.user_id != current_user.id:
            create_notification(
                db,
                member.user_id,
                "message",
                f"New message from {current_user.name}",
                payload.content[:120],
                {"conversationId": str(chat_id), "senderId": str(current_user.id)},
            )
    db.commit()
    db.refresh(message)
    payload_data = message_to_client(message)
    await manager.broadcast(chat_id, {"type": "message", "message": payload_data})

    return {"message": payload_data}


@router.post("/{conversation_id}/messages/read")
async def mark_messages_read(
    conversation_id: str,
    payload: ReadMessagesRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    chat_id = parse_uuid(conversation_id, "conversation_id")
    require_chat_member(chat_id, current_user.id, db)
    ids = [uuid.UUID(message_id) for message_id in payload.messageIds]
    if ids:
        messages = db.scalars(
            select(Message).where(Message.chat_id == chat_id, Message.id.in_(ids), Message.sender_id != current_user.id)
        ).all()
    else:
        messages = db.scalars(
            select(Message).where(Message.chat_id == chat_id, Message.sender_id != current_user.id, Message.is_read.is_(False))
        ).all()
    now = datetime.now(timezone.utc)
    for message in messages:
        message.is_read = True
        message.read_at = now
    db.commit()
    await manager.broadcast(chat_id, {"type": "messages_read", "readerId": str(current_user.id), "messageIds": [str(m.id) for m in messages]})
    return {"success": True, "messageIds": [str(m.id) for m in messages]}


@router.websocket("/{conversation_id}/ws")
async def conversation_websocket(websocket: WebSocket, conversation_id: str, token: str):
    payload = decode_access_token(token)
    if not payload or not payload.get("sub"):
        await websocket.close(code=4401)
        return
    chat_id = parse_uuid(conversation_id, "conversation_id")
    with SessionLocal() as db:
        user = db.get(User, payload["sub"])
        if not user:
            await websocket.close(code=4401)
            return
        try:
            require_chat_member(chat_id, user.id, db)
        except HTTPException:
            await websocket.close(code=4403)
            return
    await manager.connect(chat_id, websocket)
    await manager.broadcast(chat_id, {"type": "presence", "userId": payload["sub"], "status": "online"})
    try:
        while True:
            event = await websocket.receive_json()
            if event.get("type") == "typing":
                await manager.broadcast(chat_id, {"type": "typing", "userId": payload["sub"], "isTyping": bool(event.get("isTyping"))})
    except WebSocketDisconnect:
        manager.disconnect(chat_id, websocket)
        await manager.broadcast(chat_id, {"type": "presence", "userId": payload["sub"], "status": "offline"})
