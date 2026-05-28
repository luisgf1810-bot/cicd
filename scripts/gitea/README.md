# Installation and Configuration 

Install gitea chart using the commands in the script __install_gitea.sh__.
 
First, update __/etc/hosts__ with gitea.local domain.

```
127.0.0.1 localhost
127.0.1.1 enzo-Lenovo-YOGA-710-15IKB
127.0.0.1 k3d-myregistry.local
127.0.0.1 gitea.local


# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```

then add helm repo and get the configuration values __custom-values.yaml__.
```
## @section Gitea
#
gitea:
  ## @param gitea.admin.username Username for the Gitea admin user
  ## @param gitea.admin.existingSecret Use an existing secret to store admin user credentials
  ## @param gitea.admin.password Password for the Gitea admin user
  ## @param gitea.admin.email Email for the Gitea admin user
  ## @param gitea.admin.passwordMode Mode for how to set/update the admin user password. Options are: initialOnlyNoReset, initialOnlyRequireReset, and keepUpdated
  admin:
    # existingSecret: gitea-admin-secret
    existingSecret:
    username: admin
    password: admin
    email: "gitea@local.domain"
    passwordMode: keepUpdated

  ## @param gitea.metrics.enabled Enable Gitea metrics
  ## @param gitea.metrics.token used for `bearer` token authentication on metrics endpoint. If not specified or empty metrics endpoint is public.
  ## @param gitea.metrics.serviceMo
```


Disable postgresql ha and valkey ha, so only one instance will be installed and change user/pwd to admin/admin.

```
...
# Valkey cluster and [Valkey](#valkey) cannot be enabled at the same time.
## @descriptionEnd
valkey-cluster:
  ## @param valkey-cluster.enabled Enable valkey cluster
  # ⚠️ The valkey charts do not work well with special characters in the password (<https://gitea.com/gitea/helm-chart/issues/690>).
  # Consider omitting such or open an issue in the Bitnami repo and let us know once this got fixed.
  ## @param valkey-cluster.usePassword Whether to use password authentication.
  ## @param valkey-cluster.usePasswordFiles Whether to mount passwords as files instead of environment variables.
  enabled: false
  usePassword: false
  usePasswordFiles: false
...
valkey:
  ## @param valkey.enabled Enable valkey standalone or replicated
  ## @param valkey.architecture Whether to use standalone or replication
  enabled: true
  architecture: standalone
...
## @section PostgreSQL HA
postgresql-ha:
  ## @param postgresql-ha.enabled Enable PostgreSQL HA
  enabled: false
...
## @section PostgreSQL
postgresql:
  ## @param postgresql.enabled Enable PostgreSQL
  enabled: true
...
gitea:
  ## @param gitea.admin.username Username for the Gitea admin user
  ## @param gitea.admin.existingSecret Use an existing secret to store admin user credentials
  ## @param gitea.admin.password Password for the Gitea admin user
  ## @param gitea.admin.email Email for the Gitea admin user
  ## @param gitea.admin.passwordMode Mode for how to set/update the admin user password. Options are: initialOnlyNoReset, initialOnlyRequireReset, and keepUpdated
  admin:
    # existingSecret: gitea-admin-secret
    existingSecret:
    username: admin
    password: admin
    email: "gitea@local.domain"
    passwordMode: keepUpdated
```


then install with the following command:

```
helm install gitea gitea-charts/gitea -f custom-values.yaml

```

and apply an ingress using the file __ingress.yaml__:

```
kubectl apply -f ingress.yml
```

The gitea ui will be accessed on http://gitea.local

