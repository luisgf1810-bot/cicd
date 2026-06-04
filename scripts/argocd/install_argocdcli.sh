# install
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# change kubeconfig ips with the ones of the endpoints
kubectl get endpointskubect 

# Login
argocd login argocd.local

# List available contexts
kubectl config get-contexts

# Add each remote cluster
argocd cluster add k3d-development --name k3d-development
argocd cluster add k3d-gitops --name k3d-gitops
argocd cluster add k3d-production --name k3d-production

# Verify clusters
argocd cluster list