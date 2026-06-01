#!/usr/bin/env bash
set -euo pipefail

# 1. Create a k3d cluster routing container port 80 to host port 8080
echo "Creating k3d cluster..."
k3d cluster create mycluster -p "8080:80@loadbalancer" --k3s-arg "--disable=metrics-server@server:*"

# 2. Install the recommended Kubernetes Dashboard
echo "Deploying Kubernetes Dashboard..."
kubectl apply -f https://githubusercontent.com

# 3. Wait for the Dashboard deployments to become ready
echo "Waiting for dashboard pods to stabilize..."
kubectl rollout status deployment/kubernetes-dashboard -n kubernetes-dashboard --timeout=90s

# 4. Create Traefik Custom Resource Definitions (CRDs) for Insecure Routing
echo "Configuring Traefik IngressRoute and Custom Resource Definitions..."
kubectl apply -f - <<EOF
apiVersion: traefik.io/v1alpha1
kind: ServersTransport
metadata:
  name: dashboard-transport
  namespace: kubernetes-dashboard
spec:
  insecureSkipVerify: true
---
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: kubernetes-dashboard-ingress
  namespace: kubernetes-dashboard
spec:
  entryPoints:
    - web
  routes:
    - match: PathPrefix(\`/\`)
      kind: Rule
      services:
        - name: kubernetes-dashboard
          port: 443
          serversTransport: dashboard-transport
EOF

# 5. Create a ServiceAccount and ClusterRoleBinding for administrative access
echo "Creating admin user and generating access token..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

# 6. Extract and output the bearer token
echo "================================================================="
echo "Deployment Complete!"
echo "Access the dashboard here: http://localhost:8080"
echo "================================================================="
echo "Use the following Bearer Token to log in:"
echo ""
kubectl -n kubernetes-dashboard create token admin-user
echo "============================================