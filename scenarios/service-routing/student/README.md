# Mission : réparer le routage du catalogue

Le Deployment `catalog` est sain, mais `wget http://catalog` échoue. Vous devez
corriger **uniquement** le Service `catalog`.

1. Inspectez les labels des Pods et le selector du Service.
2. Inspectez le port nommé du conteneur et le `targetPort` du Service.
3. Vérifiez `kubectl get endpointslice -l kubernetes.io/service-name=catalog`.
4. Lancez le grader.

```bash
kubectl get deploy,pods,svc,endpointslice
kubectl describe service catalog
./scenarios/service-routing/grader/verify.sh
```

Objectif : deux endpoints prêts, DNS fonctionnel et HTTP accessible. Ne modifiez
ni le Deployment ni les labels des Pods pour contourner le contrat demandé.
