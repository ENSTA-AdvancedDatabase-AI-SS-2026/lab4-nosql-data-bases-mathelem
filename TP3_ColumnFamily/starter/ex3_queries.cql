-- TP3 - Exercice 3 : Requêtes CQL

USE smartgrid;

-- 3.1 Mesures d'un capteur spécifique sur les dernières 6 heures
-- Attention, il faut fournir concrètement la date d'aujourd'hui en partition key.
SELECT * FROM mesures_par_capteur
WHERE capteur_id = 11111111-1111-1111-1111-111111111111 
  AND date_jour = '2026-05-11' 
  AND timestamp >= '2026-05-11 15:00:00';


-- 3.2 Dernière mesure de chaque capteur d'une wilaya
-- Cassandra ne gère pas de GROUP BY aussi flexible sur Partition pour récupérer le dernier élement de la clustering key globalement, 
-- Vous devez spécifier le capteur. 
-- EXEMPLE : Pour un capteur donné on prend sa toute dernière remontée.
SELECT * FROM mesures_par_capteur 
WHERE capteur_id = 11111111-1111-1111-1111-111111111111
  AND date_jour = '2026-05-11' 
LIMIT 1;


-- 3.3 Capteurs en alerte dans la wilaya "Alger" aujourd'hui
-- Compter et lister
SELECT count(*) FROM alertes_par_wilaya 
WHERE wilaya = 'Alger' AND date_jour = '2026-05-11';

SELECT * FROM alertes_par_wilaya 
WHERE wilaya = 'Alger' AND date_jour = '2026-05-11';


-- 3.4 Consommation totale par heure sur une journée (dashboard)
SELECT * FROM agregats_horaires
WHERE wilaya = 'Alger' AND date_jour = '2026-05-11';


-- 3.5 Détection d'anomalie : capteurs avec tension < 200V ou > 240V
-- dans les 30 dernières minutes. 
-- C'est l'anti-pattern Cassandra par excellence de faire cela sur mesures_par_capteur car la tension n'est pas clé ! Il faudrait de l'ALLOW FILTERING.
-- La vraie solution est de faire une table dédiée (Matérialized View par exemple) ou traiter l'alerte à l'ingestion et l'insérer dans alertes_par_wilaya.
SELECT * FROM alertes_par_wilaya
WHERE wilaya = 'Alger' AND date_jour = '2026-05-11'
  AND timestamp >= '2026-05-11 20:30:00'; -- (et filtrer code_alerte côté applicatif)


-- 3.6 Top 10 capteurs les plus actifs (plus de mesures) cette semaine
-- Cassandra n'est pas conçu pour ce genre de requêtes analytiques (Top K global).
-- Cela nécessiterait Apache Spark avec le connecteur Cassandra, ou une table compteurs.


-- 3.7 Requête ALLOW FILTERING : Pourquoi éviter ?
-- Si on faisait ça :
-- SELECT * FROM mesures_par_capteur WHERE tension_v > 240 ALLOW FILTERING;
-- Cassandra irait sur CHAQUE NOEUD, scannerait CHAQUE LIGNE (Full cluster scan), effondrant les perfs du cluster à 100%. 
-- La bonne approche : si on cherche par tension, il faut une table / index secondaire partitionné par tension_v (ou alert_code) !
