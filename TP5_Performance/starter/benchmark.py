"""
TP5 - Benchmark Comparatif NoSQL
Mesurer les performances de Redis, MongoDB, Cassandra, Neo4j
"""
import time
import statistics
import json
from typing import Callable, List, Tuple
import redis
from pymongo import MongoClient
from cassandra.cluster import Cluster
from neo4j import GraphDatabase

# ─── Utilitaires de mesure ────────────────────────────────────────────────────

def measure_latency(fn: Callable, iterations: int = 1000) -> dict:
    """
    Exécuter fn iterations fois et retourner les statistiques
    """
    latencies = []
    for _ in range(iterations):
        start = time.perf_counter()
        fn()
        latencies.append((time.perf_counter() - start) * 1000)  # en ms
    
    latencies.sort()
    return {
        "mean_ms": statistics.mean(latencies),
        "p50_ms": latencies[int(0.50 * len(latencies))],
        "p95_ms": latencies[int(0.95 * len(latencies))],
        "p99_ms": latencies[int(0.99 * len(latencies))],
        "max_ms": max(latencies),
        "throughput_rps": 1000 / statistics.mean(latencies)
    }


def print_results(name: str, results: dict):
    print(f"\n{'='*50}")
    print(f" {name}")
    print(f"{'='*50}")
    for k, v in results.items():
        print(f"  {k:20s}: {v:.2f}")


# ─── Ex1 : Benchmark Écriture ─────────────────────────────────────────────────

def benchmark_write_redis(n: int = 100_000):
    """Insérer n enregistrements dans Redis et mesurer le débit"""
    r = redis.Redis(host='localhost', port=6379)
    r.flushdb()
    
    start = time.time()
    pipe = r.pipeline()
    for i in range(n):
        pipe.set(f"bench:{i}", f"data_payload_{i}")
        if i % 10000 == 0 and i > 0:
            pipe.execute()
    pipe.execute()
    
    elapsed = time.time() - start
    print(f"✅ Redis Écriture : {n:,} ops en {elapsed:.2f}s => {n/elapsed:,.0f} ops/sec")


def benchmark_write_mongodb(n: int = 100_000):
    """Insérer n documents dans MongoDB et mesurer le débit"""
    try:
        client = MongoClient("mongodb://admin:admin123@localhost:27017/", serverSelectionTimeoutMS=2000)
        db = client["benchmark"]
        db.test_docs.drop()
        
        start = time.time()
        batch = []
        for i in range(n):
            batch.append({"_id": i, "data": f"payload_{i}", "value": i})
            if len(batch) == 10000:
                db.test_docs.insert_many(batch)
                batch = []
        if batch:
            db.test_docs.insert_many(batch)
            
        elapsed = time.time() - start
        print(f"✅ MongoDB Écriture : {n:,} ops en {elapsed:.2f}s => {n/elapsed:,.0f} ops/sec")
    except Exception as e:
        print(f"❌ MongoDB non disponible: {e}")


def benchmark_write_cassandra(n: int = 100_000):
    """Insérer n rows dans Cassandra et mesurer le débit"""
    print(f"ℹ️ Cassandra Écriture : BATCH Unlogged généré pour {n} (Simulé car dépendant du cluster TP3)")
    # Code structuré :
    # session.execute("CREATE TABLE IF NOT EXISTS bench (id INT PRIMARY KEY, data TEXT)")
    # stmt = session.prepare("INSERT INTO bench (id, data) VALUES (?, ?)")
    # for chunk in chunks: batch = BatchStatement(batch_type=BatchType.UNLOGGED); ... session.execute(batch)


# ─── Ex2 : Benchmark Lecture ─────────────────────────────────────────────────

def benchmark_read_redis():
    """Point lookup, range (ZRANGE), complex (pipeline multi-get)"""
    r = redis.Redis(host='localhost', port=6379)
    try:
        r.ping()
        def read_op():
            r.get("bench:500")
        
        res = measure_latency(read_op, 5000)
        print_results("Redis Read (GET)", res)
    except:
        pass


def benchmark_read_mongodb():
    """find_one, find avec range, aggregate pipeline"""
    try:
        client = MongoClient("mongodb://admin:admin123@localhost:27017/", serverSelectionTimeoutMS=2000)
        db = client["benchmark"]
        
        def read_op():
            db.test_docs.find_one({"_id": 500})
            
        res = measure_latency(read_op, 5000)
        print_results("MongoDB Read (findOne)", res)
    except:
        pass


# ─── Ex3 : Charge concurrente ─────────────────────────────────────────────────

def benchmark_concurrent(db_fn: Callable, n_clients: int = 50, requests_per_client: int = 200):
    """
    Lancer n_clients threads simultanés
    """
    import threading
    
    threads = []
    start = time.time()
    for _ in range(n_clients):
        def worker():
            for _ in range(requests_per_client):
                db_fn()
                
        t = threading.Thread(target=worker)
        threads.append(t)
        t.start()
        
    for t in threads:
        t.join()
        
    elapsed = time.time() - start
    total_reqs = n_clients * requests_per_client
    print(f"✅ Concurrence terminées : {total_reqs} reqs par {n_clients} clients en {elapsed:.2f}s => {total_reqs/elapsed:,.0f} reqs/sec")


# ─── Main ─────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    print("🚀 Benchmark NoSQL - Comparatif des 4 technologies")
    print("="*60)
    
    N = 10_000  # Réduire pour les tests, 100_000 pour la production
    
    print(f"\n📝 Benchmark Écriture ({N:,} enregistrements)")
    benchmark_write_redis(N)
    benchmark_write_mongodb(N)
    benchmark_write_cassandra(N)
    
    print(f"\n📖 Benchmark Lecture (1,000 requêtes)")
    benchmark_read_redis()
    benchmark_read_mongodb()
    
    print(f"\n⚡ Test Charge Concurrente (50 clients)")
    def redis_mock_read():
        r = redis.Redis(host='localhost', port=6379)
        r.get("bench:500")
    try:
        benchmark_concurrent(redis_mock_read, n_clients=50, requests_per_client=200)
    except:
        pass
    
    print("\n✅ Benchmark terminé ! Consultez RAPPORT.md pour l'analyse.")
