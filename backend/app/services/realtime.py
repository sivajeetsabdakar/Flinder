from collections import defaultdict
from typing import Any
import uuid

from fastapi import WebSocket


class ConnectionManager:
    def __init__(self) -> None:
        self.rooms: dict[uuid.UUID, set[WebSocket]] = defaultdict(set)

    async def connect(self, chat_id: uuid.UUID, websocket: WebSocket) -> None:
        await websocket.accept()
        self.rooms[chat_id].add(websocket)

    def disconnect(self, chat_id: uuid.UUID, websocket: WebSocket) -> None:
        self.rooms[chat_id].discard(websocket)
        if not self.rooms[chat_id]:
            del self.rooms[chat_id]

    async def broadcast(self, chat_id: uuid.UUID, payload: dict[str, Any]) -> None:
        dead: list[WebSocket] = []
        for websocket in list(self.rooms.get(chat_id, set())):
            try:
                await websocket.send_json(payload)
            except Exception:
                dead.append(websocket)
        for websocket in dead:
            self.disconnect(chat_id, websocket)


manager = ConnectionManager()
