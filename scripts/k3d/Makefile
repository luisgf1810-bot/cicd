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

portainer:
	@docker volume create portainer_data
	@docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:lts
	kubectl config use-context k3d-development
	@kubectl apply -f https://downloads.portainer.io/ce2-39/portainer-agent-k8s-nodeport.yaml
	kubectl config use-context k3d-production
	@kubectl apply -f https://downloads.portainer.io/ce2-39/portainer-agent-k8s-nodeport.yaml
	kubectl config use-context k3d-gitops
	@kubectl apply -f https://downloads.portainer.io/ce2-39/portainer-agent-k8s-nodeport.yaml


registry:
	@k3d registry create myregistry.local --port 12345

kubeconfig-multi:
	@export KUBECONFIG=$$HOME/.kube/k3d-gitops.yaml:$$HOME/.kube/k3d-development.yaml:$HOME/.kube/k3d-production.yaml


multi: kubeconfig-multi 
	@k3d cluster create                                                                  \
		--servers 1                                                                      \
		--agents 1                                                                       \
		--api-port 64432                                                                 \
		--network multicluster                                                           \
		--image rancher/k3s:v1.21.6-k3s1                                                 \
		--token superSecretToken                                                         \
		--timeout 60s                                                                    \
		--port 8082:80@loadbalancer:0                                                    \
		--port 4432:443@loadbalancer:0                                                   \
		--k3s-arg "--cluster-cidr=10.1.0.0/16@server:0"                                  \
		--k3s-arg "--service-cidr=10.0.0.0/16@server:0"                                  \
		--k3s-arg "--etcd-disable-snapshots@server:0"                                    \
		--k3s-arg "--tls-san=k3d-development-serverlb@server:0"                          \
		--k3s-arg "--disable=network-policy@server:0"                                    \
		--k3s-arg "--disable=cloud-controller@server:0"                                  \
		--k3s-node-label tier=server@server:0                                            \
		--k3s-node-label tier=worker@agent:0                                             \
		--k3s-node-label worker=a@agent:0                                                \
		--wait development;                                                              \
																						 \
	k3d kubeconfig get development > $$HOME/.kube/k3d-development.yaml;             		 \
																						 \
	k3d cluster create                                                                   \
		--servers 1                                                                      \
		--agents 1                                                                       \
		--api-port 64433                                                                 \
		--network multicluster                                                           \
		--image rancher/k3s:v1.21.6-k3s1                                                 \
		--token superSecretToken                                                         \
		--timeout 60s                                                                    \
		--port 8083:80@loadbalancer:0                                                    \
		--port 4433:443@loadbalancer:0                                                   \
		--k3s-arg "--cluster-cidr=10.1.0.0/16@server:0"                                  \
		--k3s-arg "--service-cidr=10.0.0.0/16@server:0"                                  \
		--k3s-arg "--etcd-disable-snapshots@server:0"                                    \
		--k3s-arg "--tls-san=k3d-production-serverlb@server:0"                           \
		--k3s-arg "--disable=network-policy@server:0"                                    \
		--k3s-arg "--disable=cloud-controller@server:0"                                  \
		--k3s-node-label tier=server@server:0                                            \
		--k3s-node-label tier=worker@agent:0                                             \
		--k3s-node-label worker=a@agent:0                                                \
		--wait production;                                                               \
																						 \
	k3d kubeconfig get production > $$HOME/.kube/k3d-production.yaml;               \
																						 \
	k3d cluster create                                                                   \
		--servers 1                                                                      \
		--agents 1                                                                       \
		--api-port 64431                                                                 \
		--network multicluster                                                           \
		--image rancher/k3s:v1.21.6-k3s1                                                 \
		--token superSecretToken                                                         \
		--timeout 60s                                                                    \
		--port 8081:80@loadbalancer:0                                                    \
		--port 4431:443@loadbalancer:0                                                   \
		--k3s-arg "--cluster-cidr=10.1.0.0/16@server:0"                                  \
		--k3s-arg "--service-cidr=10.0.0.0/16@server:0"                                  \
		--k3s-arg "--etcd-disable-snapshots@server:0"                                    \
		--k3s-arg "--tls-san=k3d-gitops-serverlb@server:0"                               \
		--k3s-arg "--disable=network-policy@server:0"                                    \
		--k3s-arg "--disable=cloud-controller@server:0"                                  \
		--k3s-node-label tier=server@server:0                                            \
		--k3s-node-label tier=worker@agent:0                                             \
		--k3s-node-label worker=a@agent:0                                                \
		--wait gitops;                                                                   \
																						 \
	k3d kubeconfig get gitops > $$HOME/.kube/k3d-gitops.yaml                        \


multicluster: clean registry multi #portainer ## Create K3s multicluster/registry