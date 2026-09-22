# Versionner et distribuer le workshop

Le dépôt suit Semantic Versioning (`vMAJOR.MINOR.PATCH`). Une release représente
un contrat pédagogique reproductible : objectifs, templates, corrigé, barème et
adaptateurs évoluent ensemble.

- `PATCH` : correction sans changer le barème ni les objectifs ;
- `MINOR` : nouvel exercice compatible ou amélioration du contenu ;
- `MAJOR` : changement de contrat, de prérequis ou de notation.

Avant une release, exécuter `make validate`, tester la solution sur les modes
`sequential` et `full`, puis créer un tag signé. Les plateformes et parcours ne
doivent jamais suivre une branche mouvante : ils référencent un tag publié ou le
digest immuable de son archive. Le changelog de la release mentionne les versions
Kubernetes réellement validées.
