k3d registry create myregistry.local --port 12345
k3d cluster create --config ./clusterconfig_k3d.yaml --registry-use k3d-myregistry.local:12345