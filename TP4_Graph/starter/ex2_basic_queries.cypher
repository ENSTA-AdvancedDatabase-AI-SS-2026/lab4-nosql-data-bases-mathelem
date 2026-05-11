// TP4 - Exercice 2 : Requêtes de Base
// 2.1 Trouver tous les amis d'Ahmed (1 saut)
MATCH (ahmed:Etudiant {prenom: "Ahmed"})-[:CONNAIT]-(ami)
RETURN ami.prenom, ami.nom;

// 2.2 Trouver les amis d'amis d'Ahmed qui ne sont pas déjà ses amis
MATCH (ahmed:Etudiant {prenom: "Ahmed"})-[:CONNAIT*2]-(ami_d_ami)
WHERE NOT (ahmed)-[:CONNAIT]-(ami_d_ami) AND ahmed <> ami_d_ami
RETURN DISTINCT ami_d_ami.prenom, ami_d_ami.nom;

// 2.3 Étudiants qui suivent le même cours que Fatima mais ne la connaissent pas
MATCH (fatima:Etudiant {prenom: "Fatima"})-[:SUIT]->(c:Cours)<-[:SUIT]-(etud:Etudiant)
WHERE NOT (fatima)-[:CONNAIT]-(etud) AND fatima <> etud
RETURN DISTINCT etud.prenom, c.intitule AS cours_commun;

// 2.4 Clubs les plus populaires (par nombre de membres)
MATCH (c:Club)<-[:MEMBRE_DE]-(e:Etudiant)
RETURN c.nom, count(e) AS nombre_membres
ORDER BY nombre_membres DESC;

// 2.5 Profil complet d'un étudiant : amis, cours, compétences, clubs
MATCH (e:Etudiant {prenom: "Fatima"})
OPTIONAL MATCH (e)-[:CONNAIT]-(amis)
OPTIONAL MATCH (e)-[:SUIT]->(cours)
OPTIONAL MATCH (e)-[:MAITRISE]->(competences)
RETURN e.prenom, 
       collect(DISTINCT amis.prenom) AS liste_amis, 
       collect(DISTINCT cours.intitule) AS liste_cours, 
       collect(DISTINCT competences.nom) AS liste_competences;
