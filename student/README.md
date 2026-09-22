# Parcours étudiant

Vous disposez d'un namespace attribué par le formateur. Ne créez pas de
namespace et n'ajoutez jamais votre kubeconfig à ce dépôt.

```bash
export KUBECONFIG=/chemin/vers/le/kubeconfig-fourni
./adapters/standalone/preflight.sh
```

Complétez les manifests dans `student/manifests/`, puis appliquez-les dans
l'ordre indiqué dans `student/exercises/`. Les fichiers contiennent des
commentaires `TODO`; aucune valeur liée à un cluster particulier n'est requise.

Lorsque vous avez terminé :

```bash
./grader/verify.sh
```

Le score de passage recommandé est de 80/100. Le vérificateur ne révèle aucun
secret. Pour prouver la persistance et les règles réseau, il recrée le Pod
PostgreSQL et crée puis supprime deux Pods de test dédiés. Il ne supprime ni les
manifests évalués, ni le PVC, ni le namespace.
