
# Define directories
HLAMP := scripts/headlamp
K3D := scripts/k3d
HARBOR := scripts/harbor
GITEA := scripts/gitea
ARGOCD := scripts/argocd
REGPORT := 12345
TEST := test
GITLAB := scripts/gitlab

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
	@minikube delete

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


createmulti: kubeconfig-multi 
	@k3d cluster create                         		                                 \
		--servers 1                                                                      \
		--agents 1                                                                       \
		--api-port 64432                                                                 \
		--network multicluster                                                           \
		--image rancher/k3s:latest                                                 		\
		--token superSecretToken                                                         \
		--timeout 60s                                                                    \
		--port 80:80@loadbalancer:0													\
		--port 443:443@loadbalancer:0	                               	 		\
		--k3s-arg "--disable=traefik@server:0"      									\
		--k3s-arg "--cluster-cidr=10.1.0.0/16@server:0"                                  \
		--k3s-arg "--service-cidr=10.0.0.0/16@server:0"                                  \
		--k3s-arg "--etcd-disable-snapshots@server:0"                                    \
		--k3s-arg "--tls-san=k3d-gitops-serverlb@server:0"                          	\
		--k3s-arg "--disable=network-policy@server:0"                                    \
		--k3s-arg "--disable=cloud-controller@server:0"                                  \
		--k3s-arg "--node-taint=CriticalAddonsOnly=true:NoExecute@server:0"				\
		--k3s-node-label tier=server@server:0                                            \
		--k3s-node-label tier=worker@agent:0                                             \
		--k3s-node-label worker=a@agent:0                                                \
		--wait gitops --registry-use k3d-myregistry.local:$(REGPORT);                                                              
																						 
	@k3d kubeconfig get gitops > $$HOME/.kube/k3d-gitops.yaml;             		 
																						 
createmulti2:
	@mkcert -install
	@mkcert -CAROOT /home/luis/.local/share/mkcert
	@cat /home/luis/.local/share/mkcert/rootCA.pem
	@mkcert -key-file key.pem -cert-file cert.pem local *.local
	@mv key.pem scripts/minikube/
	@mv cert.pem scripts/minikube/
	@minikube start
	@minikube addons enable ingress
	@minikube addons enable storage-provisioner
	@minikube ip 
	@kubectl -n kube-system create secret tls mkcert --key scripts/minikube/key.pem --cert scripts/minikube/cert.pem
	@minikube addons configure ingress
	@minikube addons disable ingress
	@minikubgitlab argocde addons enable ingress

cluster: clean createmulti2 kubeconfig-multi portainer ## Create minikube cluster

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
	@helm repo updchange root cert in values.yml and apply:ate
	@helm upgrade --install gitea gitea-charts/gitea -f $(GITEA)/custom-values.yaml
	@kubectl apply -f $(GITEA)/ingress.yaml

gitlab:
	@helm repo add gitlab https://charts.gitlab.io/
	@helm repo update
	@helm install gitlab gitlab/gitlab -f $(GITLAB)/custom-values.yaml --timeout 600s

terrakube:
	@kubectl create namespace terrakube | true
	@helm repo add terrakube-repo https://charts.terrakube.io
	@helm repo update
	@export MYCERT=$(cat /home/luis/.local/share/mkcert/rootCA.pem) 
	@yq -e '.security.caCerts."rootCA.pem"=strenv(MYCERT)' scripts/terrakube/template.yaml > scripts/terrakube/values.yaml
	@helm install terrakube terrakube-repo/terrakube -n terrakube --values scripts/terrakube/values.yaml 

argocd:
	@helm repo add argo https://argoproj.github.io/argo-helm
	@helm repo update
	@helm upgrade --install argocd argo/argo-cd
	@kubectl patch configmap argocd-cmd-params-cm --type merge -p '{"data":{"server.insecure": "true"}}' 
	@kubectl patch configmap argocd-cm --type merge -p '{"data":{"url":"https://argocd.local"}}'
	@kubectl apply -f $(ARGOCD)/ingress.yaml
	@kubectl -n default get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

gitops: terrakube ## Deploy gitops tools



examples:
