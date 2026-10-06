# Adaptateur local

Le profil local recommandé pour les micro-labs CKAD est **k3d**, car K3s fournit
un provisioner de stockage et applique les NetworkPolicies par défaut. Le dépôt
n'installe ni Docker, ni k3d, ni kubectl automatiquement.

La matrice validée le 2026-10-06 est :

| Composant | Version validée |
|---|---:|
| Docker Desktop / Engine | 4.66.0 / 29.3.0 |
| k3d | 5.9.0 |
| K3s | 1.36.4+k3s1 |
| kubectl | 1.37.1 |

Créez le cluster avec un kubeconfig dédié. Le script ne modifie pas le contexte
Kubernetes par défaut :

```bash
./adapters/local/create.sh
export KUBECONFIG="$(k3d kubeconfig write ckad-local)"
./adapters/local/doctor.sh

kubectl create namespace ckad-workshop
export WORKSHOP_NAMESPACE=ckad-workshop
./scenarios/run.sh service-routing
```

Puis suivez le README étudiant du scénario et lancez son grader. Pour supprimer
uniquement le cluster créé :

```bash
k3d cluster delete ckad-local
```

Les scores locaux sont **formatifs et non vérifiés** (`local_unverified`). Une
future note officielle devra soumettre les manifests à un runner contrôlé et
être recalculée côté serveur ; aucun webhook secret n'est embarqué ici.

Le kubeconfig local est généré sous le répertoire de configuration k3d de
l'utilisateur, jamais dans ce dépôt. Conservez `KUBECONFIG` dans le terminal du
workshop pour éviter toute commande accidentelle vers un autre cluster.

Kind peut devenir un second provider, à condition d'installer et de valider un
CNI qui applique réellement les NetworkPolicies.
