# CKAD Namespace Resilience Workshop

Atelier CKAD générique de 75 minutes sur l'isolation et la résilience dans un
namespace. Il fonctionne en autonomie avec un kubeconfig fourni séparément ou
comme contenu d'une session Educates. Ce dépôt ne contient aucune information
d'accès à un cluster.

## Démarrage étudiant

```bash
git clone https://github.com/sype/ckad-namespace-workshop.git
cd ckad-namespace-workshop
git checkout vX.Y.Z                 # version indiquée par le formateur
export KUBECONFIG=/chemin/fourni
./adapters/standalone/preflight.sh
```

Suivez ensuite [le parcours étudiant](student/README.md), complétez les `TODO`
dans `student/manifests/`, puis lancez `./grader/verify.sh`.

Le namespace est lu depuis `WORKSHOP_NAMESPACE`, ou à défaut depuis le contexte
kubectl actif. Les scripts refusent `default` et les namespaces système.

## Objectifs

- appliquer une `LimitRange` et un `ResourceQuota` cohérents ;
- déployer et exposer un frontend avec ressources et readiness probe ;
- exploiter PostgreSQL dans un StatefulSet avec PVC ;
- démontrer la persistance après recréation du Pod ;
- autoriser le frontend et refuser le backend avec une NetworkPolicy ;
- diagnostiquer avec `describe`, les événements et EndpointSlice.

Le barème automatisé vaut 100 points, avec un seuil recommandé de 80. La chaîne
stateful et les deux contrôles réseau (autorisation et refus) sont obligatoires
pour réussir. Les objectifs et le détail du barème sont versionnés dans
`curriculum/`.

## Démonstration formateur

```bash
./scripts/preflight.sh
./scripts/deploy.sh                 # WORKSHOP_MODE=sequential par défaut
./scripts/test.sh
./grader/verify.sh
CONFIRM_CLEANUP=yes ./scripts/cleanup.sh
```

Le mode `sequential` convient aux clusters contraints : le frontend est validé
puis réduit à zéro avant PostgreSQL. Utilisez `WORKSHOP_MODE=full` pour conserver
tous les workloads simultanément. Aucun mode ne crée ou supprime le namespace.
Le Secret PostgreSQL est généré en mémoire et envoyé directement à l'API.

Le corrigé valide deux réplicas par défaut. Pour une validation technique sur un
cluster ne disposant que d'un seul emplacement de pod, le formateur peut utiliser
`FRONTEND_REPLICAS=1`; le parcours étudiant et le mode Educates restent à deux.

## Organisation

```text
curriculum/             objectifs, prérequis et barème
student/                consignes et templates TODO
solution/               corrigé de référence
grader/verify.sh        validation indépendante, score /100
adapters/standalone/    kubeconfig externe, namespace attribué
adapters/educates/      contenu et squelette de packaging Educates
scripts/                démonstration, tests et nettoyage formateur
tests/                  validations statiques du dépôt
```

Le dossier historique `manifests/` est conservé temporairement pour les liens
existants. La source canonique du corrigé est désormais `solution/manifests/`.

## Prérequis plateforme

- version cliente `kubectl` compatible avec le serveur ;
- namespace précréé et droits limités à celui-ci ;
- StorageClass par défaut ;
- CNI appliquant les NetworkPolicies ;
- `openssl` pour la génération du Secret.

## Publication

Les parcours et plateformes doivent référencer une release immuable, jamais une
branche mouvante. Consultez [RELEASES.md](RELEASES.md) pour la convention de tags.

## Sécurité et licence

Ne commitez jamais kubeconfig, token, mot de passe, IP interne ou donnée
personnelle. Consultez [SECURITY.md](SECURITY.md). Licence MIT - WeFactorIT.
