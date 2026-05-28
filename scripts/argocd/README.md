# Installation and Configuration 

Install argocd chart using the commands in the script __install_argocd.sh__.
 
First, update __/etc/hosts__ with __argocd.local__ domain.

```
127.0.0.1 localhost
127.0.1.1 enzo-Lenovo-YOGA-710-15IKB
127.0.0.1 k3d-myregistry.local
127.0.0.1 gitea.local
127.0.0.1 argocd.local

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```

then add helm repo, download it.

```
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
```

Then install with the following command:

```
/Develop/cicd/scripts/argocd/argo-cd$ helm install argocd argo/argo-cd 
NAME: argocd
LAST DEPLOYED: Thu May 28 14:54:50 2026
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
In order to access the server UI you have the following options:

1. kubectl port-forward service/argocd-server -n default 8080:443

    and then open the browser on http://localhost:8080 and accept the certificate

2. enable ingress in the values file `server.ingress.enabled` and either
      - Add the annotation for ssl passthrough: https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#option-1-ssl-passthrough
      - Set the `configs.params."server.insecure"` in the values file and terminate SSL at your ingress: https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#option-2-multiple-ingress-objects-and-hosts


After reaching the UI the first time you can login with username: admin and the random password generated during the installation. You can find the password by running:

kubectl -n default get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

(You should delete the initial secret afterwards as suggested by the Getting Started Guide: https://argo-cd.readthedocs.io/en/stable/getting_started/#4-login-using-the-cli)

```

then get the configmap __argocd-cmd-params-cm__:

```
kubectl get configmap argocd-cmd-params-cm -o yaml > configmap_argocd.yaml
```

Edit and add the flag __(server.insecure: "true")__:

```yaml
cat configmap_argocd.yaml 
apiVersion: v1
data:
  server.insecure: "true"
  applicationsetcontroller.enable.leader.election: "false"
  applicationsetcontroller.log.format: text
  applicationsetcontroller.log.level: info
  commitserver.log.format: text
  commitserver.log.level: info
...
```

restart argocd-server:

```
kubectl rollout restart deployment argocd-server 
```


Also, patch configmap __(argocd-cm)__ to change base url:

```
/Develop/cicd/scripts/argocd/argo-cd$ kubectl patch configmap argocd-cm --type merge -p '{"data":{"url":"https://argocd.local"}}'
configmap/argocd-cm patched
```



finally apply an ingress using the file __ingress.yaml__:

```
kubectl apply -f ingress.yml
```

The argocd ui will be accessed on http://argocd.local

To acces the ui get the user/pwd with the following command:

```
kubectl get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

```