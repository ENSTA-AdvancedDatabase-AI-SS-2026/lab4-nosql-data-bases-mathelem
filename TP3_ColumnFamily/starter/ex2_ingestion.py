"""
TP3 - Exercice 2 : Ingestion de données IoT
Use Case : SmartGrid DZ - 10 000 capteurs, 5 minutes de mesures
"""
from cassandra.cluster import Cluster
from cassandra.query import BatchStatement, BatchType
import uuid
import random
from datetime import datetime, timedelta
import time

# Configuration
CASSANDRA_HOST = 'localhost'
KEYSPACE = 'smartgrid'
NB_CAPTEURS = 10000
MINUTES_HISTORIQUE = 5

WILAYAS = ["Alger", "Oran", "Constantine", "Annaba", "Blida"]
COMMUNES = {
    "Alger": ["Bab Ezzouar", "Hydra", "El Harrach", "Dar El Beida"],
    "Oran": ["Bir El Djir", "Es Senia", "Arzew"],
    "Constantine": ["El Khroub", "Ain Smara", "Hamma Bouziane"],
    "Annaba": ["El Bouni", "El Hadjar", "Seraidi"],
    "Blida": ["Bougara", "Boufarik", "Larbaa"],
}

def connect():
    """Connexion au cluster Cassandra"""
    cluster = Cluster([CASSANDRA_HOST])
    session = cluster.connect(KEYSPACE)
    return session, cluster


def generate_mesure(capteur_id, wilaya, commune, timestamp):
    """Générer une mesure réaliste pour un capteur"""
    tension_base = 220  # Volts (réseau algérien)
    
    return {
        "capteur_id": capteur_id,
        "date_jour": timestamp.date(),
        "timestamp": timestamp,
        "wilaya": wilaya,
        "commune": commune,
        # Variation normale ± 10V
        "tension_v": round(tension_base + random.gauss(0, 5), 2),
        "courant_a": round(random.uniform(0.5, 15.0), 2),
        "puissance_kw": round(random.uniform(0.1, 3.3), 3),
        "frequence_hz": round(50 + random.gauss(0, 0.1), 2),
        "temperature": round(random.uniform(20, 65), 1),
        # 5% de chance d'alerte
        "alerte": random.random() < 0.05,
    }


def insert_single(session, mesure):
    """
    TODO: Insérer une seule mesure dans mesures_par_capteur
    Utiliser une prepared statement
    """
    query = """
        INSERT INTO mesures_par_capteur 
        (capteur_id, date_jour, timestamp, wilaya, commune, tension_v, courant_a, puissance_kw, frequence_hz, temperature, alerte) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """
    prepared = session.prepare(query)
    session.execute(prepared, (
        mesure['capteur_id'], mesure['date_jour'], mesure['timestamp'],
        mesure['wilaya'], mesure['commune'], mesure['tension_v'],
        mesure['courant_a'], mesure['puissance_kw'], mesure['frequence_hz'],
        mesure['temperature'], mesure['alerte']
    ))


def insert_batch(session, mesures: list):
    """
    TODO: Insérer un batch de mesures de manière efficace
    Utiliser UNLOGGED BATCH pour les séries temporelles
    Faire des batches de max 50 items (bonne pratique Cassandra)
    """
    query = """
        INSERT INTO mesures_par_capteur 
        (capteur_id, date_jour, timestamp, wilaya, commune, tension_v, courant_a, puissance_kw, frequence_hz, temperature, alerte) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """
    prepared = session.prepare(query)
    
    # Process in chunks of 50
    for i in range(0, len(mesures), 50):
        chunk = mesures[i:i+50]
        batch = BatchStatement(batch_type=BatchType.UNLOGGED)
        for mesure in chunk:
            batch.add(prepared, (
                mesure['capteur_id'], mesure['date_jour'], mesure['timestamp'],
                mesure['wilaya'], mesure['commune'], mesure['tension_v'],
                mesure['courant_a'], mesure['puissance_kw'], mesure['frequence_hz'],
                mesure['temperature'], mesure['alerte']
            ))
        session.execute(batch)


def run_ingestion(session):
    """
    TODO: Générer et insérer NB_CAPTEURS × MINUTES_HISTORIQUE mesures
    1. Générer les capteurs (ID aléatoires + assignation wilaya/commune)
    2. Pour chaque minute des MINUTES_HISTORIQUE dernières minutes
       → Insérer les mesures de tous les capteurs
    3. Mesurer et afficher :
       - Nombre total d'insertions
       - Durée totale
       - Débit (mesures/seconde)
    """
    print(f"Démarrage ingestion : {NB_CAPTEURS} capteurs × {MINUTES_HISTORIQUE} min")
    start = time.time()
    
    # 1. Générer le référentiel des capteurs
    capteurs = []
    for _ in range(NB_CAPTEURS):
        w = random.choice(WILAYAS)
        c = random.choice(COMMUNES[w])
        capteurs.append({'id': uuid.uuid4(), 'wilaya': w, 'commune': c})
        
    # 2. Insérer minute par minute
    base_time = datetime.now() - timedelta(minutes=MINUTES_HISTORIQUE)
    for m in range(MINUTES_HISTORIQUE):
        current_time = base_time + timedelta(minutes=m)
        print(f"Ingestion minute {m+1}/{MINUTES_HISTORIQUE}...")
        
        # We group by partition key for batches (capteur_id, date_jour)
        # For simplicity and speed in this local script, we'll just insert_batch them all (they will be grouped in chunks of 50 inside)
        mesures = []
        for cap in capteurs:
            mesure = generate_mesure(cap['id'], cap['wilaya'], cap['commune'], current_time)
            mesures.append(mesure)
            
        insert_batch(session, mesures)
    
    elapsed = time.time() - start
    total = NB_CAPTEURS * MINUTES_HISTORIQUE
    print(f"\n✅ {total:,} mesures insérées en {elapsed:.1f}s")
    print(f"   Débit : {total/elapsed:,.0f} mesures/seconde")


if __name__ == "__main__":
    session, cluster = connect()
    run_ingestion(session)
    cluster.shutdown()
