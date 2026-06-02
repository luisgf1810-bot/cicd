
# Define directories
HLAMP := scripts/headlamp
K3D := scripts/k3d
HARBOR := scripts/harbor
GITEA := scripts/gitea
ARGOCD := scripts/argocd
REGPORT := 12345
TEST := test

help: ## Usage: 'make <target>' where target is: multicluster, up, down, clean.
	@egrep '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

up: ## Starts k3s cluster
	@k3d cluster start k3d --all

down: ## Stops k3s cluster
	@k3d cluster stop k3d --all

clean: ## Destroys clusters 
	@docker rm -f portainer || true
	@docker volume rm -f portainer_data || true
	@k3d registry delete --all
	@k3d cluster delete --all 

headlamp:
	@kubectl config use-context k3d-gitops
	@helm repo add headlamp https://kubernetes-sigs.github.io/headlamp/
	@helm repo update
	@helm install my-headlamp headlamp/headlamp   --namespace kube-system
	@kubectl apply -f $(HLAMP)/gitopshl.ingress.yaml
	#@helm upgrade --install my-headlamp headlamp/headlamp -f scripts/headlamp/kubevirt.yaml -n kube-system
	@kubectl create token my-headlamp --namespace kube-system

portainer:
	@docker volume create portainer_data
	@docker run -d -p 8000:8000 -p 7443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:lts
	
registry:
	@k3d registry create myregistry.local --port $(REGPORT)

kubeconfig-multi:
	@export KUBECONFIG=$$HOME/.kube/k3d-gitops.yaml:$$HOME/.kube/k3d-development.yaml:$HOME/.kube/k3d-production.yaml
	@kubectl config view --flatten > $$HOME/.kube/config-merged 
	@mv $$HOME/.kube/config-merged $$HOME/.kube/config


multi: kubeconfig-multi 
	@k3d cluster create                         		                                 \
		--servers 1                                                                      \
		--agents 1                                                                       \
		--api-port 64432                                                                 \
		--network multicluster                                                           \
		--image rancher/k3s:latest                                                 \
		--token superSecretToken                                                         \
		--timeout 60s                                                                    \
		--port 80:80@loadbalancer:0                                                    	 \
		--port 443:443@loadbalancer:0      \
		--k3s-arg "--cluster-cidr=10.1.0.0/16@server:0"                                  \
		--k3s-arg "--service-cidr=10.0.0.0/16@server:0"                                  \
		--k3s-arg "--etcd-disable-snapshots@server:0"                                    \
		--k3s-arg "--tls-san=k3d-gitops-serverlb@server:0"                          \
		--k3s-arg "--disable=network-policy@server:0"                                    \
		--k3s-arg "--disable=cloud-controller@server:0"                                  \
		--k3s-node-label tier=server@server:0                                            \
		--k3s-node-label tier=worker@agent:0                                             \
		--k3s-node-label worker=a@agent:0                                                \
		--wait gitops --registry-use k3d-myregistry.local:$(REGPORT);                                                              
																						 
	@k3d kubeconfig get gitops > $$HOME/.kube/k3d-gitops.yaml;             		 
																						 
	@k3d cluster create                                                                   \
		--servers 1                                                                      \
		--agents 1                                                                       \
		--api-port 64433                                                                 \
		--network multicluster                                                           \
		--image rancher/k3s:v1.21.6-k3s1                                                 \
		--token superSecretToken                                                         \
		--timeout 60s                                                                    \
		--port 9080:80@loadbalancer:0                                                    	 \
		--port 9443:443@loadbalancer:0                                                    \
		--k3s-arg "--cluster-cidr=10.1.0.0/16@server:0"                                  \
		--k3s-arg "--service-cidr=10.0.0.0/16@server:0"                                  \
		--k3s-arg "--etcd-disable-snapshots@server:0"                                    \
		--k3s-arg "--tls-san=k3d-production-serverlb@server:0"                           \
		--k3s-arg "--disable=network-policy@server:0"                                    \
		--k3s-arg "--disable=cloud-controller@server:0"                                  \
		--k3s-node-label tier=server@server:0                                            \
		--k3s-node-label tier=worker@agent:0                                             \
		--k3s-node-label worker=a@agent:0                                                \
		--wait production --registry-use k3d-myregistry.local:$(REGPORT);                                                               
																						 
	@k3d kubeconfig get production > $$HOME/.kube/k3d-production.yaml;               
																						 
	@k3d cluster create                                                                   \
		--servers 1                                                                      \
		--agents 1                                                                       \
		--api-port 64431                                                                 \
		--network multicluster                                                           \
		--image rancher/k3s:v1.21.6-k3s1                                                 \
		--token superSecretToken                                                         \
		--timeout 60s                                                                    \
		--port 9081:80@loadbalancer:0                                                    	 \
		--port 9444:443@loadbalancer:0                                                    \
		--k3s-arg "--cluster-cidr=10.1.0.0/16@server:0"                                  \
		--k3s-arg "--service-cidr=10.0.0.0/16@server:0"                                  \
		--k3s-arg "--etcd-disable-snapshots@server:0"                                    \
		--k3s-arg "--tls-san=k3d-development-serverlb@server:0"                               \
		--k3s-arg "--disable=network-policy@server:0"                                    \
		--k3s-arg "--disable=cloud-controller@server:0"                                  \
		--k3s-node-label tier=server@server:0                                            \
		--k3s-node-label tier=worker@agent:0                                             \
		--k3s-node-label worker=a@agent:0                                                \
		--wait development --registry-use k3d-myregistry.local:$(REGPORT);                                                                   
																						 
	@k3d kubeconfig get development > $$HOME/.kube/k3d-development.yaml                        


multicluster: clean registry multi kubeconfig-multi portainer headlamp ## Create K3s multicluster/registry

setup:	## Install k8 tools and setup local domains
	#@sh $(K3D)/install_k3d.sh
	#@sh $(K3D)/install_helm.sh
	#@sh $(K3D)/install_kubectl.sh

testregistry:
	@kubectl config use-context $(CONTEXT)
	@kubectl delete -f $(TEST)/testapp.yaml || true
	@docker pull nginx:latest
	@docker tag nginx:latest k3d-myregistry.local:$(REGPORT)/nginx:latest
	@docker push k3d-myregistry.local:$(REGPORT)/nginx:latest
	@kubectl apply -f $(TEST)/testapp.yaml
	@kubectl get po

harbor:
	@kubectl config use-context k3d-gitops
	@helm repo add harbor https://helm.goharbor.io
	@helm repo update
	@helm upgrade --install harbor harbor/harbor -f $(HARBOR)/custom-values.yaml

	

gitea:
	@kubectl config use-context k3d-gitops
	@helm repo add gitea-charts https://dl.gitea.com/charts/
	@helm repo update
	@helm upgrade --install gitea gitea-charts/gitea -f $(GITEA)/custom-values.yaml
	@kubectl apply -f $(GITEA)/ingress.yaml

argocd:
	@helm repo add argo https://argoproj.github.io/argo-helm
	@helm repo update
	@helm upgrade --install argocd argo/argo-cd
	@kubectl patch configmap argocd-cmd-params-cm --type merge -p '{"data":{"server.insecure": "true"}}' 
	@kubectl patch configmap argocd-cm --type merge -p '{"data":{"url":"https://argocd.local"}}'
	@kubectl apply -f $(ARGOCD)/ingress.yaml
	@kubectl -n default get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

gitops: harbor gitea argocd ## Deploy gitops tools