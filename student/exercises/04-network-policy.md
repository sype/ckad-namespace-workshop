# Exercice 4 — Isolation réseau

Complétez la NetworkPolicy pour que les Pods portant les labels `app=frontend`
et `tier=web` puissent joindre PostgreSQL sur TCP/5432. Un Pod `app=backend` ne
doit pas y parvenir.

Les Pods de test fournis dans `student/manifests/` peuvent servir à valider les
deux chemins.
