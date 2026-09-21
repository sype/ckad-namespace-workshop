# CKAD Namespace Resilience Workshop

Atelier pratique CKAD consacré au namespace comme périmètre d'isolation et de
résilience. Le dépôt est générique : il ne contient ni kubeconfig, ni jeton,
ni adresse de cluster, ni donnée personnelle.

## Objectifs

- appliquer une `LimitRange` et un `ResourceQuota` ;
- déployer un frontend Nginx et un Service ClusterIP ;
- déployer PostgreSQL dans un StatefulSet avec stockage persistant ;
- vérifier la persistance après recréation du pod ;
- autoriser un client frontend et refuser un backend avec une NetworkPolicy ;
- diagnostiquer puis nettoyer les ressources de l'atelier.

Durée indicative : 75 minutes. Niveau : intermédiaire.

## Prérequis

- `kubectl` compatible avec la version du serveur Kubernetes (écart maximal
  recommandé : une version mineure) ;
- `openssl` disponible localement ;
- un kubeconfig temporaire remis séparément par le formateur ;
- un namespace déjà créé et attribué à l'étudiant ;
- une StorageClass par défaut ;
- un CNI qui applique les NetworkPolicies.

Le kubeconfig, les jetons et les mots de passe ne doivent jamais être ajoutés
à ce dépôt.

## Démarrage rapide

```bash
git clone https://github.com/sype/ckad-namespace-workshop.git
cd ckad-namespace-workshop

export KUBECONFIG="$HOME/Downloads/ckad-student.kubeconfig"

./scripts/preflight.sh
./scripts/deploy.sh
./scripts/test.sh
```

Les scripts utilisent exclusivement le namespace défini dans le contexte
courant du kubeconfig. Ils refusent `default` et les namespaces système.

## Déroulé

### 1. Vérifier l'accès

```bash
./scripts/preflight.sh
```

Le script affiche le contexte et le namespace, vérifie les droits nécessaires,
mais n'affiche ni serveur API ni jeton.

### 2. Déployer

```bash
./scripts/deploy.sh
```

Le script applique les garde-fous, valide deux réplicas Nginx, teste le Service,
puis réduit le frontend à zéro avant de créer PostgreSQL. Cette exécution
séquentielle fonctionne aussi sur un cluster ayant peu de places disponibles.

Le mot de passe PostgreSQL est généré localement avec `openssl`, envoyé
directement à l'API Kubernetes et jamais écrit dans le dépôt.

### 3. Tester

```bash
./scripts/test.sh
```

Ce test recrée le pod PostgreSQL, vérifie que `Alice` et `Bob` sont toujours
présents, puis exécute successivement les tests NetworkPolicy autorisé et refusé.

### 4. Examiner

```bash
kubectl get all,cm,secret,limitrange,resourcequota,networkpolicy,pvc
kubectl describe resourcequota workshop-quota
kubectl get events --sort-by='.metadata.creationTimestamp'
```

Le namespace étant déjà défini par le contexte, `-n` reste facultatif pour ces
commandes interactives. Les scripts, eux, passent toujours le namespace de façon
explicite.

### 5. Nettoyer

```bash
./scripts/cleanup.sh
```

Le script demande une confirmation et supprime seulement les objets connus de
l'atelier. Il ne supprime jamais le namespace ; cette opération reste sous le
contrôle du formateur.

## Arborescence

```text
.
├── manifests/
├── scripts/
│   ├── _common.sh
│   ├── preflight.sh
│   ├── deploy.sh
│   ├── test.sh
│   └── cleanup.sh
├── .github/workflows/validate.yml
├── Makefile
├── SECURITY.md
└── README.md
```

## Avertissement stockage

Le test démontre la persistance après recréation d'un pod. Il ne démontre pas
la résilience à la perte d'un nœud. La suppression du PVC ou du namespace peut
entraîner la suppression définitive des données selon la `reclaimPolicy`.

## Licence

MIT - WeFactorIT.
