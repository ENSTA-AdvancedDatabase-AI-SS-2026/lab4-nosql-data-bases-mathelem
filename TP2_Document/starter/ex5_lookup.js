/**
 * TP2 - Exercice 5 : $lookup et Données Référencées
 */
use("medical_db");

print(
  "=== 5.1 Joindre patients et analyses pour récupérer le dossier complet d'un patient ===",
);

const dossierComplet = db.patients
  .aggregate([
    { $limit: 1 }, // On prend un seul document en exemple
    {
      $lookup: {
        from: "analyses",
        localField: "_id",
        foreignField: "patient_id",
        as: "liste_analyses",
      },
    },
  ])
  .toArray();
printjson(dossierComplet);

print("\n=== 5.2 Trouver les patients dont la glycémie dépasse 1.26 g/L ===");

const badGlycemie = db.analyses
  .aggregate([
    {
      $match: {
        type: "Glycémie",
        "resultats.glycémieAJeun": { $gt: 1.26 },
      },
    },
    {
      $lookup: {
        from: "patients",
        localField: "patient_id",
        foreignField: "_id",
        as: "patient_data",
      },
    },
    { $unwind: "$patient_data" },
    {
      $project: {
        _id: 0,
        "patient_data.nom": 1,
        "patient_data.prenom": 1,
        date: 1,
        "resultats.glycémieAJeun": 1,
      },
    },
  ])
  .toArray();
printjson(badGlycemie);

print(
  "\n=== 5.3 Statistiques croisées : taux d'analyses anormales par wilaya ===",
);

const statsCroisees = db.patients
  .aggregate([
    {
      $lookup: {
        from: "analyses",
        localField: "_id",
        foreignField: "patient_id",
        as: "analyses_med",
      },
    },
    { $unwind: "$analyses_med" },
    // Exemple d'anomalie = glycémie > 1.26
    {
      $addFields: {
        isAnormal: {
          $cond: [
            {
              $and: [
                { $eq: ["$analyses_med.type", "Glycémie"] },
                { $gt: ["$analyses_med.resultats.glycémieAJeun", 1.26] },
              ],
            },
            1,
            0,
          ],
        },
      },
    },
    {
      $group: {
        _id: "$adresse.wilaya",
        total_analyses: { $sum: 1 },
        total_anormales: { $sum: "$isAnormal" },
      },
    },
    {
      $project: {
        taux_anormal: {
          $multiply: [
            { $divide: ["$total_anormales", "$total_analyses"] },
            100,
          ],
        },
      },
    },
  ])
  .toArray();
printjson(statsCroisees);
