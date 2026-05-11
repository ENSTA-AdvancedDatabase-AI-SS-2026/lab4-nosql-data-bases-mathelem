# Rapport TP2 MongoDB

## 1. Justification du choix embedding vs referencing pour chaque collection

- **Patients et Consultations (Embedding) :** Nous avons documenté/imbriqué les _consultations_ directement dans le document du _patient_. C'est optimal car lorsqu'un médecin affiche le profil clinique d'un patient, il a systématiquement besoin de ses antécédents, ses allergies ET son historique de consultations. Cela permet un affichage complet du dossier en une seule et unique requête (One-to-Few relationship).

- **Patients et Analyses (Referencing) :** Nous avons complètement séparé les _analyses_ dans une autre collection avec une clé étrangère `patient_id`. Les résultats d'analyses (ECG, imagerie, historiques continus biologiques) grossissent continuellement sans limite au fil des années (One-to-Squillions relationship), ce qui briserait la limite de 16 MB par document de MongoDB si on persistait avec un modèle imbriqué. Le $lookup permet de réassembler les données seulement lorsque cela est nécessaire.

## 2. Résultats `explain()` avant/après indexation

Requête : `{"adresse.wilaya": "Alger", antecedents: "Diabète type 2"}`

| Scénario   | Docs examinés | Temps d'exécution (ms) | Remarque                                                                          |
| ---------- | ------------- | ---------------------- | --------------------------------------------------------------------------------- |
| Sans index | 20            | 3 ms                   | Il faut parcourir l'intégralité de la collection (Full Collection Scan).          |
| Avec index | 1             | 0 ms                   | Utilisation de l'Index composé `{ "adresse.wilaya": 1, "antecedents": 1 }`. O(1). |

## 3. Requête la plus complexe : expliquer le pipeline étape par étape

### 3.5 Rapport Médecins

```javascript
db.patients.aggregate([
  // Étape 1: aplatir la liste de consultations (1 item par consultation)
  { $unwind: "$consultations" },
  // Étape 2: Grouper par le nom du medecin traitant en comptant les rows et les ID des patients en Array  (set ignore les doublons)
  {
    $group: {
      _id: "$consultations.medecin.nom",
      patients_uniques_array: { $addToSet: "$_id" },
      total_consultations: { $sum: 1 },
    },
  },
  // Étape 3: Compter mathématiquement le nombre de patients sans doublon traités
  {
    $addFields: {
      patients_uniques: { $size: "$patients_uniques_array" },
    },
  },
  // Étape 4: Application stricte de la formule du re-consultation ((ConsultTotal - Patients)*100)/(Patients)
  {
    $addFields: {
      taux_reconsultation: {
        $multiply: [
          {
            $divide: [
              { $subtract: ["$total_consultations", "$patients_uniques"] },
              "$patients_uniques",
            ],
          },
          100,
        ],
      },
    },
  },
  // Étape 5 et 6: Top décroissant, garder le podium du top 5
  { $sort: { total_consultations: -1 } },
  { $limit: 5 },
  // Étape 7: Retirer la projection trop lourde et non utile de l'array
  { $project: { patients_uniques_array: 0 } },
]);
```
