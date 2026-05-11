/**
 * TP2 - Exercice 2 : Requêtes de Base
 */
use("medical_db");

print(
  "=== 2.1 Trouver tous les patients diabétiques de plus de 50 ans à Alger ===",
);
const oldDiabetics = db.patients
  .find({
    "adresse.wilaya": "Alger",
    antecedents: "Diabète type 2",
    // 50 ans = ne avant 1976
    dateNaissance: { $lte: new Date("1976-01-01") },
  })
  .toArray();
// printjson(oldDiabetics);

print(
  "\n=== 2.2 Patients allergiques à la Pénicilline avec au moins 3 consultations ===",
);
const penicillinAllergic = db.patients
  .find({
    allergies: "Pénicilline",
    $expr: {
      $gte: [{ $size: { $ifNull: ["$consultations", []] } }, 3],
    },
  })
  .toArray();
// printjson(penicillinAllergic);

print(
  "\n=== 2.3 Projection : Nom, prénom, et dernière consultation seulement ===",
);
const patientsProjection = db.patients
  .find(
    {},
    {
      _id: 0,
      nom: 1,
      prenom: 1,
      derniereConsultation: { $slice: ["$consultations", -1] },
    },
  )
  .limit(5)
  .toArray();
// printjson(patientsProjection);

print(
  "\n=== 2.4 Patients sans antécédents dont la tension systolique > 140 en dernière consultation ===",
);
const tensionHaut = db.patients
  .aggregate([
    { $match: { antecedents: { $size: 0 } } },
    {
      $addFields: {
        derniereConsultation: { $arrayElemAt: ["$consultations", -1] },
      },
    },
    { $match: { "derniereConsultation.tension.systolique": { $gt: 140 } } },
  ])
  .toArray();
// printjson(tensionHaut);

print("\n=== 2.5 Recherche textuelle sur les diagnostics ===");
// Il faut le text index de l'éxèrcise 4 pour que cette requete fonctionne
// db.patients.find({ $text: { $search: "Hypertension" } }).toArray();
