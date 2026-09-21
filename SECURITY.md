# Security policy

Ce dépôt ne doit contenir aucune information d'accès à un cluster.

Ne créez jamais de commit contenant :

- un kubeconfig ou un jeton de ServiceAccount ;
- une adresse privée, un nom d'hôte interne ou un certificat client ;
- un véritable Secret Kubernetes ;
- un fichier `.env` ;
- un nom d'étudiant, de client ou d'environnement interne ;
- une sortie de commande contenant des identifiants d'infrastructure.

Les secrets de démonstration sont générés à l'exécution et restent dans le
namespace temporaire. En cas de divulgation, révoquez immédiatement le jeton ou
le compte concerné et purgez l'historique Git avant toute publication.
