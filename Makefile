
# Define directories
USER_HOME := $(HOME)
HLAMP := scripts/headlamp
HARBOR := scripts/harbor
GITEA := scripts/gitea
ARGOCD := scripts/argocd
GITLAB := scripts/gitlab
TERRAKUBE := scripts/terrakube
SEMAPHOREUI := scripts/semaphoreui
AWX := scripts/awx
REGPORT := 12345
TEST := test



# Commands
help: ## Usage: make <command> 
	@egrep '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

cluster: clean helmrepos createcluster management registry ## Create minikube cluster

gitops: gitea semaphoreui argocd  ## Deploy gitops tools

gitopslegacy: gitea argocd awx terrakube ## Deploy gitops legacy tools

browser: ## Open all ui forntends
	@x-terminal-emulator -- bash -c "google-chrome http://headlamp.minikube.net http://harbor.minikube.net http://gitea.minikube.net http://argocd.minikube.net http://semaphoreui.minikube.net" &

clean: ## Destroys clusters 
	@echo "---------------------------------------"
	@echo "Clean all"
	@echo "---------------------------------------"
	@docker rm -f portainer || true
	@docker volume rm -f portainer_data || true
	@k3d registry delete --all
	@k3d cluster delete --all 
	@minikube delete


testregistry: ## Test registry 
	@echo "---------------------------------------"
	@echo "Testing registry"
	@echo "---------------------------------------"
	@kubectl delete -f $(HARBOR)/testpod.yaml || true
	@docker pull nginx:latest
	@docker tag nginx:latest harbor.minikube.net/library/nginx:latest
	@docker login harbor.minikube.net -u admin -p admin
	@docker push harbor.minikube.net/library/nginx:latest
	@kubectl apply -f $(HARBOR)/testpod.yaml
	@kubectl get po

registry: harbor 

management: headlamp portainer


# Cluster
helmrepos:
	@echo "---------------------------------------"
	@echo "Update helm repos"
	@echo "---------------------------------------"
	@helm repo add headlamp https://kubernetes-sigs.github.io/headlamp/
	@helm repo add harbor https://helm.goharbor.io
	@helm repo add gitea-charts https://dl.gitea.com/charts/
	@helm repo add awx-operator https://ansible-community.github.io/awx-operator-helm/
	@helm repo add argo https://argoproj.github.io/argo-helm
	@helm repo add terrakube-repo https://charts.terrakube.io
	@helm repo add semaphoreui https://semaphoreui.github.io/charts
	@helm repo update


createcluster:
	@echo "---------------------------------------"
	@echo " Cerate MINIKUBE cluste and custom cert"
	@echo "---------------------------------------"
	@mkcert -install
	@mkcert -CAROOT $(USER_HOME)/.local/share/mkcert
	@cat $(USER_HOME)/.local/share/mkcert/rootCA.pem
	@mkcert -key-file key.pem -cert-file cert.pem minikube.net *.minikube.net
	@minikube start --cpus=4 --memory=6g --insecure-registry="harbor.minikube.net"
	@minikube addons enable ingress
	@minikube addons enable storage-provisioner
	@minikube ip 
	@kubectl -n kube-system create secret tls mkcert --key key.pem --cert cert.pem
	@echo "kube-system/mkcert" | minikube addons configure ingress
	@minikube addons disable ingress
	@minikube addons enable ingress
	@mv key.pem scripts/minikube/
	@mv cert.pem scripts/minikube/
	@export KUBECONFIG=$$HOME/.kube/k3d-gitops.yaml:$$HOME/.kube/k3d-development.yaml:$HOME/.kube/k3d-production.yaml
	@kubectl config view --flatten > $$HOME/.kube/config-merged 
	@mv $$HOME/.kube/config-merged $$HOME/.kube/config
	@kubectl wait --for=condition=Ready pod -l app.kubernetes.io/component=controller --timeout=90s -n ingress-nginx



# Management
headlamp:
	@echo "---------------------------------------"
	@echo "K8/Docker management tools"
	@echo "---------------------------------------"
	@helm repo add headlamp https://kubernetes-sigs.github.io/headlamp/
	@helm repo update
	@helm install headlamp headlamp/headlamp --namespace kube-system
	@kubectl apply -f $(HLAMP)/ingress.yaml
	@kubectl create token headlamp --namespace kube-system || true



portainer:
	@docker volume create portainer_data
	@docker run -d -p 8000:8000 -p 7443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:lts
																					


# Registry
harbor:
	@echo "---------------------------------------"
	@echo "Creating Registry"
	@echo "---------------------------------------"
	@helm install registry harbor/harbor --namespace harbor --create-namespace --set expose.type="clusterIP" --set expose.tls.enabled="false" --set registry.relativeurls="true" --set expose.clusterIP.name="harbor" --set expose.clusterIP.ports.httpPort="8080" --set externalURL="http://harbor.minikube.net:8080" --set harborAdminPassword="admin" --set registry.credentials.username="admin" --set registry.credentials.password="admin"
	@kubectl apply -f $(HARBOR)/ingress.yaml
	@ssh -o UserKnownHostsFile=/dev/null  -o StrictHostKeyChecking=no   -i $$(minikube ssh-key) docker@$$(minikube ip)  "sudo /bin/sh -c 'echo $(kubectl -n devops get svc | grep -v '-' | awk '{print $3 "   harbor.minikube.net"}') >> /etc/hosts'"
	@kubectl create secret docker-registry harbor --docker-server="harbor.minikube.net:8080" --docker-username="admin" --docker-password="admin" || true





# Gitops
gitea:
	@helm install gitea gitea-charts/gitea -f $(GITEA)/custom-values.yaml -n gitea --create-namespace
	@kubectl apply -f $(GITEA)/ingress.yaml




argocd:
	@helm install argocd argo/argo-cd -n argocd --create-namespace
	@kubectl patch configmap argocd-cmd-params-cm -n argocd --type merge -p '{"data":{"server.insecure": "true"}}' 
	@kubectl patch configmap argocd-cm -n argocd --type merge -p '{"data":{"url":"https://argocd.minikube.net"}}'
	@kubectl apply -f $(ARGOCD)/ingress.yaml
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d


awx:
	@helm install my-awx-operator awx-operator/awx-operator -n awx --create-namespace
	@cd scripts/awx && kubectl apply -k .
	@kubectl get secret awx-demo-admin-password -n awx -o jsonpath="{.data.password}" | base64 --decode 
	@kubectl apply -f $(AWX)/ingress.yaml 


terrakube:
	@kubectl create namespace terrakube || true
	#@export MYCERT=$(cat $$HOME/.local/share/mkcert/rootCA.pem) 
	#@yq -e '.security.caCerts."rootCA.pem"=strenv(MYCERT)' scripts/terrakube/template.yaml > $(TERRAKUBE)/values.yaml
	@helm install terrakube terrakube-repo/terrakube -n terrakube --values $(TERRAKUBE)/values.yaml 


semaphoreui:
	@helm install semaphore semaphoreui/semaphore -n semaphoreui --create-namespace -f $(SEMAPHOREUI)/values.yaml
	@kubectl apply -f $(SEMAPHOREUI)/ingress.yaml


