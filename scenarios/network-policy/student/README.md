# Mission : politique réseau à privilège minimal

Les Pods `api`, `client-allowed` et `client-blocked` sont déjà prêts. Créez :

1. `default-deny` sélectionnant tous les Pods et isolant Ingress + Egress ;
2. `allow-dns` autorisant UDP et TCP 53 vers le namespace `kube-system` ;
3. `allow-api` autorisant `access=api` vers `app=api` sur TCP/8080, dans les
   deux sens nécessaires (`ingress` côté API, `egress` côté client).

Vérifiez ensuite :

```bash
kubectl exec client-allowed -- wget -qO- -T 5 http://api:8080
kubectl exec client-blocked -- wget -qO- -T 5 http://api:8080   # doit échouer
./scenarios/network-policy/grader/verify.sh
```

Ne modifiez ni les labels ni les Pods. Le grader exige les policies et les
comportements runtime.
