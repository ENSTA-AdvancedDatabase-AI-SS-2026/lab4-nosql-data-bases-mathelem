/**
 * TP2 - Exercice 1 : Modélisation MongoDB
 * Use Case : HealthCare DZ - Dossiers Médicaux
 */

// Se connecter à la base médicale
use("medical_db");

// ─── 1.1 : Créer la collection avec validation ────────────────────────────────
// TODO: Décommenter et compléter le validator $jsonSchema
db.createCollection("patients", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["cin", "nom", "prenom", "dateNaissance", "sexe"],
      properties: {
        cin: { bsonType: "string", description: "CIN obligatoire" },
        nom: { bsonType: "string", description: "Nom obligatoire" },
        prenom: { bsonType: "string", description: "Prénom obligatoire" },
        dateNaissance: {
          bsonType: "date",
          description: "Date de naissance obligatoire",
        },
        sexe: { enum: ["M", "F"], description: "Sexe doit être M ou F" },
        adresse: {
          bsonType: "object",
          required: ["wilaya"],
          properties: {
            wilaya: { bsonType: "string" },
            commune: { bsonType: "string" },
          },
        },
        groupeSanguin: {
          enum: ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"],
        },
        antecedents: { bsonType: "array", items: { bsonType: "string" } },
        allergies: { bsonType: "array", items: { bsonType: "string" } },
        consultations: { bsonType: "array", items: { bsonType: "object" } },
      },
    },
  },
});

// ─── 1.2 : Insérer des patients avec données algériennes ──────────────────────
// TODO: Insérer au moins 20 patients avec :
// - Prénoms et noms algériens variés
// - Wilayas différentes (Alger, Oran, Constantine, Annaba, Blida...)
// - Pathologies courantes (Diabète, HTA, Asthme, etc.)
// - Au moins 2-5 consultations par patient
// - Dates réalistes sur les 2 dernières années

const patients = [
  {
    cin: "198001012300",
    nom: "Bensalem",
    prenom: "Ahmed",
    dateNaissance: new Date("1980-01-01"),
    sexe: "M",
    adresse: { wilaya: "Alger", commune: "Bab Ezzouar" },
    groupeSanguin: "O+",
    antecedents: ["Diabète type 2", "HTA"],
    allergies: ["Pénicilline"],
    consultations: [
      {
        id: UUID(),
        date: new Date("2024-01-15"),
        medecin: { nom: "Dr. Mansouri", specialite: "Cardiologie" },
        diagnostic: "Hypertension artérielle",
        tension: { systolique: 145, diastolique: 92 },
        medicaments: [{ nom: "Amlodipine", dosage: "5mg", duree: "30 jours" }],
        notes: "Surveillance tensionnelle recommandée",
      },
      {
        id: UUID(),
        date: new Date("2024-03-20"),
        medecin: { nom: "Dr. Bouzid", specialite: "Endocrinologie" },
        diagnostic: "Diabète déséquilibré",
        tension: { systolique: 130, diastolique: 80 },
        medicaments: [
          { nom: "Metformine", dosage: "850mg", duree: "90 jours" },
        ],
        notes: "HbA1c à contrôler dans 3 mois",
      },
    ],
  },
  {
    cin: "197508154567",
    nom: "Mebarki",
    prenom: "Leila",
    dateNaissance: new Date("1975-08-15"),
    sexe: "F",
    adresse: { wilaya: "Oran", commune: "Es Senia" },
    groupeSanguin: "A+",
    antecedents: ["Asthme"],
    allergies: ["Pollen"],
    consultations: [
      {
        id: UUID(),
        date: new Date("2023-11-10"),
        medecin: { nom: "Dr. Lahlou", specialite: "Pneumologie" },
        diagnostic: "Crise d'asthme",
        tension: { systolique: 120, diastolique: 80 },
        medicaments: [
          { nom: "Salbutamol", dosage: "100µg", duree: "Si besoin" },
          { nom: "Corticostéroïdes", dosage: "20mg", duree: "5 jours" },
        ],
        notes: "Ventoline à garder sur soi",
      },
    ],
  },
  {
    cin: "196005221234",
    nom: "Kaddour",
    prenom: "Mohamed",
    dateNaissance: new Date("1952-05-22"),
    sexe: "M",
    adresse: { wilaya: "Constantine", commune: "Khroub" },
    groupeSanguin: "B-",
    antecedents: ["Diabète type 2", "HTA", "Cardiopathie"],
    allergies: [],
    consultations: [
      {
        id: UUID(),
        date: new Date("2024-02-14"),
        medecin: { nom: "Dr. Mansouri", specialite: "Cardiologie" },
        diagnostic: "Hypertension artérielle",
        tension: { systolique: 155, diastolique: 95 },
        medicaments: [{ nom: "Amlodipine", dosage: "10mg", duree: "Mois" }],
        notes: "Tension trop élevée",
      },
    ],
  },
];

// Generate 17 more mocked patients to reach 20 total.
const villes = [
  "Annaba",
  "Blida",
  "Setif",
  "Batna",
  "Tlemcen",
  "Bejaia",
  "Tizi Ouzou",
  "Biskra",
  "Chlef",
  "Jijel",
  "Sidi Bel Abbes",
  "Mostaganem",
  "Skikda",
  "Tiaret",
  "Guelma",
  "Tebessa",
  "Medea",
];
for (let i = 0; i < 17; i++) {
  patients.push({
    cin: "19901010" + i.toString().padStart(4, "0"),
    nom: `Nom${i}`,
    prenom: `Prenom${i}`,
    dateNaissance: new Date(`19${60 + (i % 30)}-01-01`),
    sexe: i % 2 === 0 ? "M" : "F",
    adresse: { wilaya: villes[i], commune: "Centre" },
    groupeSanguin: "O+",
    antecedents: i % 3 === 0 ? ["Diabète type 2"] : [],
    allergies: [],
    consultations: [
      {
        id: UUID(),
        date: new Date(`2023-${(i % 12) + 1}-01`),
        medecin: {
          nom: "Dr. X",
          specialite: i % 2 === 0 ? "Généraliste" : "Cardiologie",
        },
        diagnostic: "Consultation de routine",
        tension: { systolique: 120, diastolique: 80 },
        medicaments: [
          { nom: "Paracétamol", dosage: "1000mg", duree: "3 jours" },
        ],
        notes: "RAS",
      },
    ],
  });
}

db.patients.insertMany(patients);

// ─── 1.3 : Collection analyses (référencée) ───────────────────────────────────
// TODO: Créer des analyses pour les patients insérés
// Types : "Glycémie", "NFS", "Lipidogramme", "Créatinine", "ECG"

const storedPatients = db.patients.find().toArray();
const analyses = [
  {
    patient_id: storedPatients[0]._id,
    date: new Date("2024-01-16"),
    type: "Lipidogramme",
    resultats: { cholesterol: 2.1, triglycérides: 1.8 },
    laboratoire: "Labo Central Bab Ezzouar",
    valide: true,
  },
  {
    patient_id: storedPatients[0]._id,
    date: new Date("2024-03-21"),
    type: "Glycémie",
    resultats: { glycémieAJeun: 1.35 },
    laboratoire: "Labo Pasteur",
    valide: true,
  },
  {
    patient_id: storedPatients[1]._id,
    date: new Date("2023-11-11"),
    type: "NFS",
    resultats: { hemoglobine: 13.5, leucocytes: 7500 },
    laboratoire: "Labo Oran Santé",
    valide: true,
  },
];

db.analyses.insertMany(analyses);

print(
  "✅ Modélisation terminée. Patients insérés:",
  db.patients.countDocuments(),
);
print("✅ Analyses insérées:", db.analyses.countDocuments());
