# Installation and Configuration 

Create the gitea container and update /etc/hosts with __gitea.local__ domain:

```
docker-compose up -d

luis@pcdev:~/Develop/movi/cicd/scripts/gitea$ docker compose up -d
WARN[0000] /home/luis/Develop/movi/cicd/scripts/gitea/docker-compose.yml: the attribute `version` is obsolete, it will be ignored, please remove it to avoid potential confusion 
[+] up 2/2
 ✔ Network gitea_default Created                                                                                       0.0s
 ✔ Container gitea       Started                                                                                       0.2s
 ```

 Then go to http://gitea.local:3000 and install.

 