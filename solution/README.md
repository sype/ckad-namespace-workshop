# Corrigé formateur

Les manifests de ce dossier représentent l'état attendu. Ils servent aux tests
de compatibilité et au mode de démonstration, pas au parcours étudiant.

```bash
WORKSHOP_MODE=sequential ./scripts/deploy.sh
./scripts/test.sh
./grader/verify.sh
```

Le mode `sequential`, utilisé par défaut, limite le nombre de Pods simultanés.
Le mode `full` conserve le frontend pendant le déploiement de PostgreSQL.
