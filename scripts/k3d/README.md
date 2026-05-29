# Installation and Configuration 

## Prepare localhost

Add an entry to __/etc/hosts__ with __127.0.0.1 k3-myregistry.local__ for the image registry.



## Install k3d, kubectl and helm

Install using __install _k3d.sh__ , __install_kubectl.sh__ and __install_helm.sh__ files.

```
luis@pcdev:~/Develop/movi/cicd/scripts/k3d$ ./install_k3d.sh 
Preparing to install k3d into /usr/local/bin
[sudo: authenticate] Password:    
k3d installed into /usr/local/bin/k3d
Run 'k3d --help' to see what you can do with it.
```


```
luis@pcdev:~/Develop/movi/cicd/scripts/k3d$ sudo ./install_kubectl.sh
  % Total    % Received % Xferd  Average Speed  Time    Time    Time   Current
                                 Dload  Upload  Total   Spent   Left   Speed
100 56.74M 100 56.74M   0      0 11.08M      0   00:05   00:05         11.07M
luis@pcdev:~/Develop/movi/cicd/scripts/k3d$ kubectl
kubectl controls the Kubernetes cluster manager.

 Find more information at: https://kubernetes.io/docs/reference/kubectl/

Basic Commands (Beginner):
  create          Create a resource from a file or from stdin
  expose          Take a replication controller, service, deployment or pod and expose it as a new Kubernetes service
  run             Run a particular image on the cluster
  set             Set specific features on objects

Basic Commands (Intermediate):
  explain         Get documentation for a resource
  get             Display one or many resources
  edit            Edit a resource on the server
  delete          Delete resources by file names, stdin, resources and names, or by resources and label selector
```

```
enzo@enzo:~/Develop/cicd/scripts/k3d$ sudo ./install_helm.sh
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
curl is already the newest version (8.18.0-1ubuntu2.1).
gpg is already the newest version (2.4.8-4ubuntu3).
apt-transport-https is already the newest version (3.2.0).
Solving dependencies... Done
The following package was automatically installed and is no longer required:
  grub-pc-bin
Use 'sudo apt autoremove' to remove it.
0 upgraded, 0 newly installed, 0 to remove and 37 not upgraded.
deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main
Get:1 file:/var/cuda-repo-ubuntu2404-13-2-local  InRelease [1,572 B]
Get:1 file:/var/cuda-repo-ubuntu2404-13-2-local  InRelease [1,572 B]
Hit:2 http://security.ubuntu.com/ubuntu resolute-security InRelease      
Hit:3 https://packages.microsoft.com/repos/code stable InRelease         
Hit:4 https://dl.google.com/linux/chrome-stable/deb stable InRelease     
Hit:5 http://archive.ubuntu.com/ubuntu resolute InRelease           
Hit:6 http://archive.ubuntu.com/ubuntu resolute-updates InRelease
Hit:8 http://archive.ubuntu.com/ubuntu resolute-backports InRelease
Hit:7 https://packages.buildkite.com/helm-linux/helm-debian/any any InRelease
Reading package lists... Done
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
helm is already the newest version (3.20.0-1).
Solving dependencies... Done
The following package was automatically installed and is no longer required:
  grub-pc-bin
Use 'sudo apt autoremove' to remove it.
0 upgraded, 0 newly installed, 0 to remove and 37 not upgraded.
```

if kubectl does not work check config file in $HOME/.kube directory.

The commnad __k3d kubeconfig__ get can be used for troubleshooting.

## Create K8s Cluster/Registry using createcluster_k3d.sh script

Change k8s cluster settings (nodes, images, etc) using the yaml file __clusterconfig_k3d.yaml.__.

```yaml
apiVersion: k3d.io/v1alpha5
kind: Simple
metadata:
  name: mycluster
servers: 1
agents: 2
kubeAPI:
  hostPort: "6443"
image: rancher/k3s:latest
ports:
  - port: 443:443
    nodeFilters:
      - loadbalancer
  - port: 80:80
    nodeFilters:
      - loadbalancer
  - port: 8080:8080
    nodeFilters:
      - loadbalancer
```

then execute __createcluster_k3d.sh__ :

```
INFO[0000] portmapping '1443:443' targets the loadbalancer: defaulting to [servers:*:proxy agents:*:proxy] 
INFO[0000] portmapping '1080:80' targets the loadbalancer: defaulting to [servers:*:proxy agents:*:proxy] 
INFO[0000] Prep: Network                                
INFO[0000] Re-using existing network 'k3d-mycluster' (ce8ab81bc8bb7e24add2d85a63047b5d0b6090cccee97d27937254fcb4834ee1) 
INFO[0000] Created image volume k3d-mycluster-images    
INFO[0000] Starting new tools node...                   
INFO[0001] Creating node 'k3d-mycluster-server-0'       
INFO[0001] Pulling image 'ghcr.io/k3d-io/k3d-tools:5.8.3' 
INFO[0003] Pulling image 'rancher/k3s:latest'           
INFO[0004] Starting node 'k3d-mycluster-tools'          
INFO[0013] Creating node 'k3d-mycluster-agent-0'        
INFO[0013] Creating node 'k3d-mycluster-agent-1'        
INFO[0013] Creating LoadBalancer 'k3d-mycluster-serverlb' 
INFO[0015] Pulling image 'ghcr.io/k3d-io/k3d-proxy:5.8.3' 
INFO[0020] Using the k3d-tools node to gather environment information 
INFO[0020] HostIP: using network gateway 172.19.0.1 address 
INFO[0020] Starting cluster 'mycluster'                 
INFO[0020] Starting servers...                          
INFO[0020] Starting node 'k3d-mycluster-server-0'       
INFO[0028] Starting agents...                           
INFO[0028] Starting node 'k3d-mycluster-agent-1'        
INFO[0028] Starting node 'k3d-mycluster-agent-0'        
INFO[0032] Starting helpers...                          
INFO[0032] Starting node 'k3d-mycluster-serverlb'       
INFO[0038] Injecting records for hostAliases (incl. host.k3d.internal) and for 4 network members into CoreDNS configmap... 
INFO[0040] Cluster 'mycluster' created successfully!    
INFO[0040] You can now use it like this:                
kubectl cluster-info
```

execute __kubectl cluster-info__ to check and verify the k8 cluster.
```
luis@pcdev:~/Develop/movi/cicd/scripts/k3d$ kubectl cluster-info
Kubernetes control plane is running at https://0.0.0.0:6443
CoreDNS is running at https://0.0.0.0:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://0.0.0.0:6443/api/v1/namespaces/kube-system/services/https:metrics-server:https/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
luis@pcdev:~/Develop/movi/cicd/scripts/k3d$ kubectl get nodes
NAME                     STATUS   ROLES           AGE     VERSION
k3d-mycluster-agent-0    Ready    <none>          4m15s   v1.34.1+k3s1
k3d-mycluster-agent-1    Ready    <none>          4m15s   v1.34.1+k3s1
k3d-mycluster-server-0   Ready    control-plane   4m19s   v1.34.1+k3s1
luis@pcdev:~/Develop/movi/cicd/scripts/k3d$ kubectl get po --all-namespaces
NAMESPACE     NAME                                      READY   STATUS      RESTARTS   AGE
kube-system   coredns-7896679cc-2znj8                   1/1     Running     0          4m24s
kube-system   helm-install-traefik-crd-fd8cn            0/1     Completed   0          4m24s
kube-system   helm-install-traefik-dbsxb                0/1     Completed   0          4m24s
kube-system   local-path-provisioner-578895bd58-5kxsd   1/1     Running     0          4m24s
kube-system   metrics-server-7b9c9c4b9c-phwjw           1/1     Running     0          4m24s
kube-system   svclb-traefik-5861ee9e-4dw8v              2/2     Running     0          3m57s
kube-system   svclb-traefik-5861ee9e-4sv79              2/2     Running     0          3m57s
kube-system   svclb-traefik-5861ee9e-qczlj              2/2     Running     0          3m57s
kube-system   traefik-6f986b958c-9trcw                  1/1     Running     0          3m57s
```


## Test Docker registry and k8 connectivity

Using the file __testapp.yml__ check the k8 connectivity with the registry.

First, pull, tag and push the image to the registry:

```
docker pull nginx:latest
docker tag nginx:latest k3d-myregistry.local:12345/nginx:latest
docker push k3d-myregistry.local:12345/nginx:latest
```

Then apply the configuration:


```
kubectl apply -f testapp.yml 

```

and verify the pod was created:

```
luis@pcdev:~/Develop/movi/cicd/scripts/k3d$ kubectl get po
NAME                                   READY   STATUS    RESTARTS   AGE
nginx-test-registry-675455fb49-l9f87   1/1     Running   0          2s
```