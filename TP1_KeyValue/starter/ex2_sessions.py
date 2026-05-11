"""
TP1 - Exercice 2 : Sessions utilisateur
Use Case : Gestion des sessions
"""
import redis
import uuid
import time
from typing import Optional

r = redis.Redis(host='localhost', port=6379, decode_responses=True)


def create_session(r, user_id: str, ttl: int = 1800) -> str:
    """Créer une session avec un TTL"""
    session_id = str(uuid.uuid4())
    key = f"session:{session_id}"
    r.hset(key, mapping={"user_id": user_id, "created_at": time.time()})
    r.expire(key, ttl)
    return session_id


def get_session(r, session_id: str, ttl: int = 1800) -> Optional[str]:
    """Récupérer une session et renouveler son TTL"""
    key = f"session:{session_id}"
    if r.exists(key):
        r.expire(key, ttl)
        return r.hget(key, "user_id")
    return None


def delete_session(r, session_id: str):
    """Supprimer une session"""
    r.delete(f"session:{session_id}")
