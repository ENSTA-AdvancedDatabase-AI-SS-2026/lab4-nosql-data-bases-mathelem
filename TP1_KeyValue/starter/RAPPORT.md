# Rapport TP1 Redis

## 1. Comparaison de performance (hit vs miss)

L'utilisation de Redis permet de diviser la latence par environ 1000 lors d'un cache hit, évitant le temps d'attente de la base de données relationnelle sous-jacente (ex: 2000ms pour un miss en base, contre ~1ms en hit Redis).

## 2. Justification des choix de modélisation

- **Hash** a été utilisé pour stocker les produits car Redis gère extrêmement bien l'accès par sous-champs d'un dictionnaire.
- **Set** pour les catégories permet de faire des intersections rapides via `SINTER`.
- **List** est idéal pour conserver l'ordre d'un historique.
- **Sorted Set** est la structure native pour les classements.

## 3. Réponses aux questions de réflexion

1. **Que se passe-t-il si Redis redémarre ?**
   Tout dépend de la configuration de persistance (RDB / AOF). S'il n'y a pas de persistance, la RAM est vidée, toutes les données sont perdues et la BD relationnelle va subir une surcharge (Cache Stampede).
2. **Comment gérer la cohérence cache/DB en cas d'accès concurrent ?**
   Il faut implémenter des verrous distribués, ou bien gérer l'invalidation depuis l'application via des mécanismes pub/sub, écouter le log (CDC), ou un pattern cache-aside avec invalidation au moment de la mise à jour (écrire d'abord en BDD, puis delete dans Redis).
3. **Quand un TTL trop court est-il problématique ?**
   Il engendre de fréquents Cache Miss. La charge est alors transférée constamment vers la BDD principale (Thrashing), ce qui annule tout le bénéfice d'avoir un cache.
