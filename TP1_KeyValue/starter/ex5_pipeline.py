"""
TP1 - Exercice 5 : Pipeline & Transactions
Use Case : Bulk insert
"""
import redis

r = redis.Redis(host='localhost', port=6379, decode_responses=True)

def bulk_insert_products(r, products: list):
    """
    Insérer plusieurs produits en une seule requête (Pipeline)
    products: [{"id": 1, "name": "...", "price": ...}, ...]
    """
    pipe = r.pipeline()
    for p in products:
        key = f"product:{p['id']}"
        pipe.hset(key, mapping=p)
    pipe.execute()

def checkout_cart(r, user_id: str):
    """
    Simuler une transaction d'achat
    Récupérer le panier puis le vider de façon atomique
    """
    cart_key = f"cart:{user_id}"
    pipe = r.pipeline(transaction=True)
    try:
        pipe.watch(cart_key)
        cart = pipe.hgetall(cart_key)
        pipe.multi()
        pipe.delete(cart_key)
        pipe.execute()
        return cart
    except redis.WatchError:
        return None
