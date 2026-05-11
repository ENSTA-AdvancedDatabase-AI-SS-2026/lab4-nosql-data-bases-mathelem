# Rapport TP5 Benchmark Comparatif

## Tableau Décisionnel

| Critère            | Redis                                                                 | MongoDB                                                    | Cassandra                                                                          | Neo4j                                                            |
| ------------------ | --------------------------------------------------------------------- | ---------------------------------------------------------- | ---------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| Débit écriture     | Exceptionnel (En mémoire, RAM-bound). Pipeline multi-GET ultra rapide | Elevé (BSON Btree Index)                                   | Indétrônable / Infini (Log-structured LSM trees). Échelle linéaire avec les noeuds | Modéré à lent (Transactional locks complexes)                    |
| Débit lecture      | < 1ms constant, en RAM.                                               | ~2ms (BSON lookup par Index)                               | Rapide (O(1) sur Partition Key unique)                                             | Fortement variable selon la profondeur du graphe                 |
| Requêtes complexes | Basique (Lists, Hash, Sets)                                           | Avancée (Pipelines d'Aggregation sur les JSON)             | Très Faible (Obligation de cloner la donnée)                                       | Infinie / Magique (Cypher Graph Traversal, Pattern Match)        |
| Scalabilité        | Moyenne (Sharding via Redis Cluster fragile)                          | Haute (Sharding / Replica Sets)                            | Parfaite (Architecture Masterless Distribuée P2P)                                  | Limitée (Difficile techniquement de distribuer des relations)    |
| **Use case idéal** | High-Speed Cache, Sessions, Leaderboard, PubSub                       | E-Commerce, Catalogues, JSON flexibles, Content Management | Big Data Historique, logs IoT infinis, Séries temporelles massive                  | Moteurs de recommandation, réseaux sociaux, routing, anti-fraude |

## Conclusion du Benchmark Technologique

- L'utilisation pure in-memory de **Redis** écrase littéralement les 3 autres lorsqu'il s'agit de servir un cache unitaire trivial.
- **Cassandra** n'a aucun égal en écriture distribuée si on utilise impérativement le `TimeWindowStrategy` et les Unlogged Batches (Ingestion de Logs).
- **MongoDB** a prouvé être le "relational-killer" par excellence au vu de l'arsenal offert par `$lookup` et les `$group`, offrant le meilleur rapport Performance écriture/Agilité requête du marché.
- **Neo4j** sacrifie grandement ses `INSERT` mais son architecture de nodes interconnectés résout instantanément la maladie des Jointures Récursives qui met au tapis n'importe quelle BDD SQL après 3 niveaux de relations.
