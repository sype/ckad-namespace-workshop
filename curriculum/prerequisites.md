# Prérequis de la plateforme

Le formateur fournit un namespace déjà créé et un accès limité à celui-ci. Le
lab ne crée ni ne supprime de namespace.

La plateforme doit proposer une StorageClass par défaut et appliquer les
NetworkPolicies. Le compte étudiant doit pouvoir gérer les workloads, Services,
ConfigMaps, Secrets, PVC, LimitRanges, ResourceQuotas et NetworkPolicies dans le
namespace attribué, ainsi qu'exécuter une commande dans un Pod.

Le kubeconfig et toute information d'accès sont transmis hors de ce dépôt.
