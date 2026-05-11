// TP4 - Exercice 4 : Requêtes Avancées

// 4.1 Trouver un tuteur
// "Étudiant en Master qui maîtrise Python et a eu >14/20 en BDD"
MATCH (tuteur:Etudiant)-[:MAITRISE]->(comp:Competence {nom: "Python"}),
      (tuteur)-[r:SUIT]->(cours:Cours {intitule: "Bases de Données Avancées"})
WHERE tuteur.annee >= 4 AND r.note > 14
RETURN tuteur.prenom, tuteur.universite, r.note AS note_BDD;

// 4.2 Réseau alumni dans une entreprise
// "Qui de mon réseau (jusqu'à 3 sauts) travaille chez Sonatrach ?"
MATCH (moi:Etudiant {prenom: "Ahmed"})-[:CONNAIT*1..3]-(contact:Etudiant)-[:A_STAGE_CHEZ]->(ent:Entreprise {nom: "Sonatrach"})
WHERE moi <> contact
RETURN DISTINCT contact.prenom, contact.universite;

// 4.3 Détection de ponts
// Quels étudiants connectent des communautés isolées ?
// Ce n'est pas aisé de détecter un "pont" sans un algorithme GDS spécialisé comme l'Articualtion Points
// Une approche cypher basique est de trouver quelqu'un reliant 2 étudiants qui partagent AUCUN autre chemin entre eux.
MATCH (a:Etudiant)-[:CONNAIT]-(pont:Etudiant)-[:CONNAIT]-(b:Etudiant)
WHERE a <> b AND pont <> a AND pont <> b
AND NOT (a)-[:CONNAIT]-(b)
RETURN pont.prenom AS nom_du_pont, count(DISTINCT a) as pont_potentiels
ORDER BY pont_potentiels DESC
LIMIT 5;

// 4.4 Analyse temporelle
// Croissance du réseau : nouvelles connexions par mois
// Ici le "depuis" était inséré juste en année "2023", donc on aggrège sur ça
MATCH ()-[c:CONNAIT]->()
RETURN c.depuis AS annee, count(c) AS nouvelles_connexions
ORDER BY annee ASC;

// 4.5 Score de similarité
// Étudiants les plus similaires à Ahmed (cours, compétences, clubs)
// Utiliser le coefficient de Jaccard
MATCH (moi:Etudiant {prenom: "Ahmed"}), (autre:Etudiant)
WHERE moi <> autre
OPTIONAL MATCH (moi)-[:SUIT|MEMBRE_DE|MAITRISE]->(item)<-[:SUIT|MEMBRE_DE|MAITRISE]-(autre)
WITH moi, autre, collect(DISTINCT item) as intersection
MATCH (moi)-[:SUIT|MEMBRE_DE|MAITRISE]->(moi_items)
WITH moi, autre, intersection, collect(DISTINCT moi_items) as set1
MATCH (autre)-[:SUIT|MEMBRE_DE|MAITRISE]->(autre_items)
WITH autre, intersection, set1, collect(DISTINCT autre_items) as set2
WITH autre, size(intersection) AS numerateur,
     size(set1) + size(set2) - size(intersection) as denominateur
WHERE denominateur > 0
RETURN autre.prenom, toFloat(numerateur)/denominateur AS jaccard_index
ORDER BY jaccard_index DESC
LIMIT 5;
