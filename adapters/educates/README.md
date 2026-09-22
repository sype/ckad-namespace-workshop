# Adaptateur Educates

Ce dossier est un paquet générique à intégrer dans une source de workshops
Educates. Il ne contient aucun endpoint, identifiant LTI, registre privé ou
secret. L'intégrateur référence une release Git immuable et configure ces
éléments dans son dépôt d'infrastructure privé.

Contrat d'exécution :

- Educates fournit un namespace isolé à la session ;
- `kubectl` pointe déjà sur ce namespace ;
- une StorageClass par défaut et un CNI NetworkPolicy sont disponibles ;
- le contenu du dépôt est placé dans `~/exercises` ;
- la commande de validation est `~/exercises/grader/verify.sh`.

`resources/workshop.yaml` est un squelette sans URL de téléchargement. Le
champ de provenance du contenu doit être ajouté par la plateforme et épinglé
sur un tag `vX.Y.Z` ou, idéalement, sur son digest d'archive.
