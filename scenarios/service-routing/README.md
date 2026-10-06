# Service routing

Micro-lab CKAD de diagnostic applicatif. Le workload est sain, mais le Service
ne possède aucun endpoint à cause d'un sélecteur et d'un `targetPort` erronés.

```bash
./scenarios/run.sh service-routing
./scenarios/service-routing/grader/verify.sh
```

Le grader crée puis supprime un Pod de sonde. Il ne modifie pas les ressources
évaluées.
