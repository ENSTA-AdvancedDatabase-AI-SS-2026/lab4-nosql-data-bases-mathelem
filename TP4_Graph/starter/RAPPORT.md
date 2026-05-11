# Rapport TP4 Neo4j UniConnect DZ

## 1. Schéma du graphe

Le schéma généré dépeint le noeud central `(:Etudiant)` rayonnant autour du référentiel cognitif et géographique.

- Les Etudiants pointent entre eux avec du relationnel réciproque `[:CONNAIT]`.
- Les Étudiants ciblent `[:SUIT]` vers `(:Cours)`, `[:MEMBRE_DE]` vers `(:Club)`.
- Les Cours ont des dépendances directes orientées `[:REQUIERT]->(:Competence)`.

_(Un diagramme fléché peut être visualisé avec la fonction "Database Information > Nodes" dans l'UI web Neo4J `:7474`)_

## 2. Résultats de l'algorithme de communautés (Louvain)

L'algorithme de Louvain classe les Noeuds par densité d'interconnexion (Modularity).
À l'évaluation GDS dans les requêtes de test (ex3.4), les communautés générées par `CALL gds.louvain.stream('reseau_social')` font souvent apparaitre des bulles fermées représentant statistiquement les étudiants de la même filière ou la même Université. Nos liens artificiels pseudo-aléatoires créent par définition des écosystèmes fractionnés, le Louvain ID a permis de grouper mathématiquement les plus rapprochés sous un identifiant de sous-graphe unique.

## 3. Comparaison Requête SQL vs Cypher

### Use-Case : "Trouver les amis d'amis de Ahmed" (2 sauts / Friend of friend recommendations)

**Avec PostgreSQL (Relationnel Classique)**:

```sql
SELECT DISTINCT ami_de_ami.prenom
FROM etudiants e
JOIN connaitre c1 ON e.id = c1.id_etudiant1
JOIN etudiants ami ON c1.id_etudiant2 = ami.id
JOIN connaitre c2 ON ami.id = c2.id_etudiant1
JOIN etudiants ami_de_ami ON c2.id_etudiant2 = ami_de_ami.id
WHERE e.prenom = 'Ahmed'
  AND ami_de_ami.id != e.id
  AND ami_de_ami.id NOT IN (
      SELECT id_etudiant2 FROM connaitre WHERE id_etudiant1 = e.id
  );
```

_Complexité technique & cognitive extrêmement élevée pour seulement 2 sauts relationnels. Le SGBD doit réaliser des JOIN cartésiens couteux et de multiples analyses index_.

**Avec Neo4J (Cypher)**:

```cypher
MATCH (ahmed:Etudiant {prenom: "Ahmed"})-[:CONNAIT*2]-(suggestion)
WHERE NOT (ahmed)-[:CONNAIT]-(suggestion)
RETURN suggestion.prenom
```

_La complexité algorithmique du SGBD Graphe est radicalement O(x) de base car Cypher **ne fait que suivre physiquement la ligne du pont** direct sans scanner l'entièreté de la base, tout en étant visuellement ASCII-art._
