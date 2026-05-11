# Rapport TP3 Cassandra

## 1. Justification de chaque Partition Key (risque de hot partition ?)

- **Table `mesures_par_capteur`** : Nous avons utilisé une clé composée `((capteur_id, date_jour))`. Si nous utilisions uniquement `capteur_id`, les capteurs IoT ingérant des données à la seconde feraient grossir leur unique partition à l'infini (des gigaoctets entiers). C'est ce qu'on appel une _Hot Partition_. En rajoutant `date_jour`, on "bucket" (sectionne) artificiellement la partition à chaque jour (max ~1440 rangées/jour/capteur à 1 minute d'intervalle).
- **Table `alertes_par_wilaya`** : `((wilaya, date_jour))`. Même principe.
- **Table `agregats_horaires`** : `((wilaya, date_jour))`. L'agrégation restreint le nombre total d'entrées. Au maximum 24 rangées (une par heure) par partition/wilaya/jour vont être générées. Idéal pour une lecture instantannée du dashboard par requête.

## 2. Pourquoi ALLOW FILTERING est dangereux en production

`ALLOW FILTERING` demande à la base de données de filtrer une valeur sur un champ non-indexé (ou qui n'est pas dans la Primary/Clustering Key) en lisant _absolument tout_ le cluster et en écartant les non-correspondances à la volée.
En production sur un Big Data IoT avec 1 milliard de lignes réparties sur 10 nœuds distincts réseau, un seul `ALLOW FILTERING` va engorger le réseau interne et faire fumer les I/O de disques de l'ensemble du système pour de longues minutes. Toute lecture non prévue explicitement à la modélisation nécessite la création d'une **nouvelle table dénormalisée**. "Query-driven design."

## 3. Comparaison TWCS vs STCS vs LCS : quand utiliser chacun ?

- **STCS (SizeTieredCompactionStrategy)** : Regroupe des SSTables de taille similaire entre elles. Excellent pour les Write-Heavy workloads standards (par défaut dans Cassandra).
- **LCS (LeveledCompactionStrategy)** : Empile et hiérarchise strictement des petits SSTables (par défaut 160MB). Assure que presqu'aucune donnée ancienne (écrasée) perdure. Idéal pour du forte-lecture (Read-Heavy) avec beaucoup de modifications/UPDATE.
- **TWCS (TimeWindowCompactionStrategy)** : Regroupe les données ingérées _ensemble à la même minute/heure/jour_ au même endroit, puis gèle le ficher. Imbattable pour des **Time Series** comme nos données IoT: les vieux fichiers sont supprimés sans aucune restructuration une fois que leur TTL expire.
