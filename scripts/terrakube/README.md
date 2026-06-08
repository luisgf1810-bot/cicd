# Installation and Configuration 


kubectl -n kube-system create secret tls mkcert --key scripts/terrakube/key.pem --cert scripts/terrakube/cert.pem

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx   --namespace kube-system --set controller.ingressClassResource.name=nginx   --set controller.ingressClassResource.default=true 

kubectl patch deployment ingress-nginx-controller --type='json' -p='[{"op": "add",
 "path": "/spec/template/spec/containers/0/args/-", "value": "--default-ssl-certificate=kube-system/mkcert"}]' -n kube-system 

 kubectl rollout restart deployment/ingress-nginx-controller -n ingress-nginx

check values

kubectl -n kube-system get deployment ingress-nginx-controller -o yaml 

  helm install terrakube terrakube-repo/terrakube -n terrakube --values scripts/terrakube/nginx_values.yaml 