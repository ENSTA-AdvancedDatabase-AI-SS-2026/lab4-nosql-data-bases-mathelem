// TP4 - Exercice 1 : Création du graphe UniConnect DZ
// Effacer la base pour partir propre
MATCH (n) DETACH DELETE n;

// ─── 1.1 : Contraintes d'unicité ─────────────────────────────────────────────
CREATE CONSTRAINT etudiant_id IF NOT EXISTS FOR (e:Etudiant) REQUIRE e.id IS UNIQUE;
CREATE CONSTRAINT cours_code IF NOT EXISTS FOR (c:Cours) REQUIRE c.code IS UNIQUE;
CREATE CONSTRAINT competence_nom IF NOT EXISTS FOR (c:Competence) REQUIRE c.nom IS UNIQUE;

// ─── 1.2 : Créer les compétences ──────────────────────────────────────────────
UNWIND [
  {nom: "Python", categorie: "Programmation"},
  {nom: "Java", categorie: "Programmation"},
  {nom: "SQL", categorie: "Bases de Données"},
  {nom: "NoSQL", categorie: "Bases de Données"},
  {nom: "Machine Learning", categorie: "IA"},
  {nom: "Deep Learning", categorie: "IA"},
  {nom: "React", categorie: "Web"},
  {nom: "Docker", categorie: "DevOps"},
  {nom: "Linux", categorie: "Systèmes"},
  {nom: "Réseaux", categorie: "Infrastructure"}
] AS comp
MERGE (:Competence {nom: comp.nom, categorie: comp.categorie});

// ─── 1.3 : Créer les cours ────────────────────────────────────────────────────
UNWIND [
  {code: "INFO401", intitule: "Bases de Données Avancées", credits: 6, dept: "Informatique"},
  {code: "INFO402", intitule: "Intelligence Artificielle", credits: 6, dept: "Informatique"},
  {code: "INFO403", intitule: "Développement Web", credits: 4, dept: "Informatique"},
  {code: "INFO404", intitule: "Systèmes Distribués", credits: 5, dept: "Informatique"},
  {code: "INFO405", intitule: "Cloud Computing", credits: 4, dept: "Informatique"}
] AS cours
MERGE (:Cours {code: cours.code, intitule: cours.intitule, 
               credits: cours.credits, departement: cours.dept});

// ─── 1.4 : Importer et Créer les étudiants depuis CSV ────────────────────────
// Utiliser LOAD CSV avec le fichier import/students.csv
LOAD CSV WITH HEADERS FROM 'file:///students.csv' AS row
MERGE (e:Etudiant {id: row.id})
SET e.prenom = row.prenom,
    e.nom = row.nom,
    e.universite = row.universite,
    e.filiere = row.filiere,
    e.annee = toInteger(row.annee),
    e.ville = row.ville;

// ─── 1.5 : Créer des étudiants mock supplémentaires (Pour atteindre 50+) ─────
UNWIND range(11, 50) AS i
MERGE (e:Etudiant {id: "E0" + i})
SET e.prenom = "Prenom" + i,
    e.nom = "Nom" + i,
    e.universite = ["USTHB", "UMBB", "USTO", "UMC", "UBMA"][i % 5],
    e.filiere = ["Informatique", "Mathématiques", "Electronique", "Telecoms", "GL"][i % 5],
    e.annee = (i % 5) + 1,
    e.ville = ["Alger", "Boumerdes", "Oran", "Constantine", "Annaba"][i % 5];

// ─── 1.6 : Créer Clubs et Entreprises ──────────────────────────────────────
MERGE (:Club {nom: "Club IA USTHB", universite: "USTHB", domaine: "IA"})
MERGE (:Club {nom: "CyberSec UMBB", universite: "UMBB", domaine: "Sécurité"})
MERGE (:Entreprise {nom: "Sonatrach", secteur: "Energie", ville: "Alger"})
MERGE (:Entreprise {nom: "Yassir", secteur: "Tech", ville: "Alger"});

// ─── 1.7 : Créer les relations ────────────────────────────────────────────────
// Utiliser le cartesian product aléatoire pour lier CONNAIT
MATCH (e1:Etudiant), (e2:Etudiant)
WHERE e1.id < e2.id AND rand() < 0.05
MERGE (e1)-[:CONNAIT {depuis: 2023}]->(e2)
MERGE (e2)-[:CONNAIT {depuis: 2023}]->(e1);

// Lier Étudiants -> Cours
MATCH (e:Etudiant), (c:Cours)
WHERE rand() < 0.2
MERGE (e)-[:SUIT {semestre: 1, note: toInteger(rand() * 10) + 10}]->(c);

// Lier Étudiants -> Compétence
MATCH (e:Etudiant), (comp:Competence)
WHERE rand() < 0.15
MERGE (e)-[:MAITRISE {niveau: "Intermédiaire"}]->(comp);

// Lier Cours -> Compétences requises
MATCH (c:Cours {code: "INFO402"}), (comp:Competence {nom: "Python"})
MERGE (c)-[:REQUIERT]->(comp);
MATCH (c:Cours {code: "INFO402"}), (comp:Competence {nom: "Machine Learning"})
MERGE (c)-[:REQUIERT]->(comp);

// Lier Étudiants -> Club
MATCH (e:Etudiant {universite: "USTHB"}), (club:Club {universite: "USTHB"})
WHERE rand() < 0.3
MERGE (e)-[:MEMBRE_DE {role: "Membre"}]->(club);

// Lier Étudiant -> Entreprise
MATCH (e:Etudiant)
WHERE e.id = "E002" OR e.id = "E020"
MATCH (ent:Entreprise {nom: "Sonatrach"})
MERGE (e)-[:A_STAGE_CHEZ {annee: 2024, duree_mois: 3}]->(ent);

// ─── 1.8 : Vérification ───────────────────────────────────────────────────────
MATCH (n) RETURN labels(n)[0] AS type, count(n) AS total ORDER BY total DESC;
MATCH ()-[r]->() RETURN type(r) AS relation, count(r) AS total ORDER BY total DESC;
