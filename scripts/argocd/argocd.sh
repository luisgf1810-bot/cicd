  kubectl create ns cicd
  cd argo-helm/charts/argocd-cd
  helm dependency up
  helm install cicd . -f values.yaml -n cicd --set server.service.type=NodePort --set server.service.nodePortHttp=30080 --set server.service.nodePortHttps=30443
  kubectl get po -n cicd
  kubectl patch svc argocd-server -n argocd --type='json' \
  -p='[
    {"op": "replace", "path": "/spec/ports/0/port", "value": 8080},
    {"op": "replace", "path": "/spec/ports/0/name", "value": "http"},
    {"op": "replace", "path": "/spec/ports/1/port", "value": 8443},
    {"op": "replace", "path": "/spec/ports/1/name", "value": "https"}
  ]'
  kubectl port-forward svc/argocd-server -n argocd 8443:8443
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo