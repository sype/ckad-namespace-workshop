# Exercice 3 — PostgreSQL stateful

Créez d'abord le Secret à l'exécution :

```bash
./adapters/standalone/create-secret.sh
```

Complétez la ConfigMap, le Service headless et le StatefulSet. PostgreSQL doit
utiliser un PVC, initialiser deux utilisateurs (`Alice` et `Bob`) et exposer une
readiness probe. Supprimez ensuite son Pod et démontrez que les données restent.
