-- TP3 - Exercice 4 : Compaction et Maintenance
USE smartgrid;

-- 4.1 Choisir la stratégie de compaction pour chaque table
-- Pour les Time Series (nos capteurs/alertes), l'ordre d'insertion représente strictement l'ordre du temps.
-- Une fois un "bucket" de temps passé, les données ne sont plus modifiées.
-- TWCS (TimeWindowCompactionStrategy) est parfaite car elle regroupe les SSTables uniquement par fenêtres temporelles (ex: fichiers de 1 jour). Il devient alors de l'O(1) temporel pour effacer des vieux fichiers (via TTL).


-- 4.2 Configurer TWCS pour les mesures
ALTER TABLE mesures_par_capteur
WITH compaction = {
  'class': 'TimeWindowCompactionStrategy',
  'compaction_window_unit': 'DAYS',
  'compaction_window_size': 1
};

ALTER TABLE alertes_par_wilaya
WITH compaction = {
  'class': 'TimeWindowCompactionStrategy',
  'compaction_window_unit': 'DAYS',
  'compaction_window_size': 1
};


-- 4.3 Vérifier l'utilisation des TTL
-- On peut vérifier sur une donnée insérée qu'elle possède bien le `TTL(nom_colonne)` 
-- (combien de secondes il lui reste)
SELECT capteur_id, timestamp, TTL(tension_v) FROM mesures_par_capteur LIMIT 5;


-- 4.4 Analyser une partition "hot" : comment la détecter et la corriger ?
-- Détection : Les commandes `nodetool tablestats` et `nodetool cfhistograms` montrent la taille moyenne/maximale des partitions. Si Max >> Avg, il y a une hot partition.
-- Correction : Ajouter une granularité à la Clé de Partition (le "bucketing"). 
-- Par exemple, on a fait exprès de passer de `PRIMARY KEY (capteur_id)` à `PRIMARY KEY ((capteur_id, date_jour))` dans le TP !
