# Single Machine OIH install

This is a docker-compose wrapper providing all of the services for the OIH search engine on one docker-compose stack for development or staging deployment.

It includes
* nginx-proxy as a web proxy to access the website and the api
* A lets-encrypt sidecar for nginx-proxy to provide for certificates. If you are running on a local/non-internet accessible domain, this will silently fall back to HTTP rather than HTTPS.
* Container definitons for the API, web, and solr instances.

## Installation

### Prerequisites

The description here is for a Ubuntu Linux server but should not be too different for another machine.

- update/upgrade the server
```
sudo apt update 
sudo apt upgrade
sudo apt autoclean
sudo apt autoremove
```
- GIT
```
sudo apt install git
```
- docker config /etc/docker/daemon.json should contain
```
{
  "data-root": "/data/docker"
}
```
- docker (see https://phoenixnap.com/kb/install-docker-on-ubuntu-20-04)
```
sudo apt remove docker docker-engine docker.io containerd runc
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-cache policy docker-ce
sudo apt install docker-ce -y
```
- checker if docker is running correctly
```
sudo systemctl status docker
```
- [npm]
- server has a mounted volume on /data with minimum 50G (should be 100G)

### Get the code

To install the complete interface
- clone this repository **and all the submodules** where you think everything should reside
```
git clone --recurse-submodules git@github.com:iodepo/oih-ui-docker.git /data/oih-ui-docker
```
- to be sure that we are using the correct code from the submodules it's best to checkout a known tag for each of them
```
cd /data/oih-ui-docker/frontend/frontend
git pull
git checkout 0.4.3
```
- check if this is ok
```
git status
HEAD detached at 0.4.3
```
- make a symlink from /data/oih-ui-docker/docker-compose.yml to either 
  - /data/oih-ui-docker/docker-compose.external.yml for production server
  - /data/oih-ui-docker/docker-compose.dev.yml for dev server

### Configure

To make the env file we need you can either make it:

```
cd /data/oih-ui-docker
make
```

or you can rename the env.sample file to .env and change the content.

Running `make` will give a list of makefile commands of interest.
```
cd /data/oih-ui-docker
make

make
sed: can't read .env: No such file or directory
./make_env.py

Making the ENV file...

Hostname? stag.search.oceaninfohub.org
Help: 
init: submodule initialization and updates
down: brings the docker-compose set down 
up: brings the docker-compose set up 
logs | logs-web: tails webserver logs 
logs-solr: tails solr logs 
logs-api: tails api logs 
logs-nginx: tails nginx logs 
logs-le: tails nginx lets-encrypt 
initdb-solr: prepares the solr database 
```

Put all the dockers up
```
cd /data/oih-ui-docker/
make up
```

Create the SOLR db:

```
cd /data/oih-ui-docker
make initdb-solr
docker-compose run -u root solr chown solr:solr /var/solr/data/ckan/data
Creating oih-ui-docker_solr_run ... done
```

### Put everything together
this should not be needed anymore, all containers should be running now
```
make up
docker ps
9f97426ac4c1   nginxproxy/acme-companion       "/bin/bash /app/entr…"   16 minutes ago   Up 16 minutes                                              oih-ui-docker_letsencrypt-nginx-proxy-companion_1
a874506b60a8   oih-ui-docker_web               "docker-entrypoint.s…"   16 minutes ago   Up 16 minutes                                              oih-ui-docker_web_1
f6e83ad5e0eb   nginxproxy/nginx-proxy:latest   "/app/docker-entrypo…"   16 minutes ago   Up 16 minutes   0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp   oih-ui-docker_nginx-proxy_1
59cf8919d72e   solr:8                          "docker-entrypoint.s…"   16 minutes ago   Up 16 minutes                                              oih-ui-docker_solr_1
1a9443dbd9ca   oih-ui-docker_api               "uvicorn api.main:ap…"   16 minutes ago   Up 16 minutes   8000/tcp                                   oih-ui-docker_api_1

```
At this point, the system should be up and running, though without any indexed documents.

## Settings Details

The docker compose sets some environment variables that are important for connecting between the various services.

### API

The api is assumed to be at `api.hostname`, the website at `hostname` (as set in the .env file by make_env.py) This can be changed in the environment variables `VIRTUAL_HOST` for the proxy service and `LETSENCRYPT_HOST` for the lets-encrypt ssl cert. For development work, I find it useful to map `*.localhost` to my local machine, so `oih.localhost` and `api.oih.localhost` automatically resolve to my dev machine.

If you change the API url, the setting for `REACT_APP_DATA_SERVICE_URL` in the web environment needs to be changed to match.

### Solr

The `SOLR_JAVA_MEM` setting may require tweaking to allow for more memory to be used by the solr process, depending on the machine size.

## Updating
When updating the server after commits to the [oih-ui repo](https://github.com/iodepo/oih-ui/) you will need to pull in those changes here.

As we are using (should be using) tags for the submodules, we can checkout the desired tag in the resp. submodule.
```
cd /data/oih-ui-docker/frontend/frontend
git pull
git checkout 0.4.3
git status
   #HEAD detached at 0.4.3
```
