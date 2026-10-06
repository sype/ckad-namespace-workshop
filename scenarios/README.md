# Scénarios CKAD

Chaque scénario conserve la même séparation que le capstone : contrat
pédagogique, parcours étudiant, corrigé, setup, nettoyage et grader.

| ID | Durée | Compétences CKAD |
|---|---:|---|
| `service-routing` | 25 min | Service, selectors, targetPort, EndpointSlice, DNS, diagnostic |
| `network-policy` | 35 min | default-deny, DNS egress, règles ingress/egress, tests positif/négatif |

Lancez un scénario dans un namespace dédié :

```bash
export WORKSHOP_NAMESPACE=ckad-workshop
./scenarios/run.sh service-routing
```

Le runner refuse `default`, les namespaces système et toute valeur ne
correspondant pas à `ckad-*` ou `workshop-*`.
