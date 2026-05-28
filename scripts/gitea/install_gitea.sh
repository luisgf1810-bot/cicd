helm repo add gitea-charts https://dl.gitea.com/charts/
helm repo update
helm show values gitea-charts/gitea > custom-values.yaml
helm install gitea gitea-charts/gitea -f custom-values.yaml