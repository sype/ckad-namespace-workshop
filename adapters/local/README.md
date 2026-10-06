# Adaptateur local

Le profil local recommandé pour les micro-labs CKAD est **k3d**, car K3s fournit
un provisioner de stockage et applique les NetworkPolicies par défaut. Le dépôt
n'installe ni Docker ni k3d automatiquement.

```bash
k3d cluster create ckad-local --servers 1 --agents 1 --wait
kubectl config use-context k3d-ckad-local
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

Kind peut devenir un second provider, à condition d'installer et de valider un
CNI qui applique réellement les NetworkPolicies.
