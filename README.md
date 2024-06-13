![Logo](https://oceaninfohub.org/wp-content/uploads/2020/12/logo_OIH_PNG-RGB-1.png)

# Setup Instructions for OIH UI Docker

this setup instructions are made to install the complete Ocean Info Hub (OIH) search interface on a Linux server 
- recent Ubuntu server is used, but all recent Linux distros should work identical
- you will need (ssh) shell access to that machine and be in the [sudoers list](https://linux.die.net/man/5/sudoers) or connect as root
- you will need minimum 50G of free disc space in one partition, here we assume you will use ***/data*** as the installation dir 
(replace /data with whatever dir you want to use of course)
```bash
df -h /data
```
should give something like:
```bash
Filesystem      Size  Used Avail Use% Mounted on
/dev/sdb1       50G   1G  49G   2% /data
```
- if you will use this as a real production server you might need more disc space in the future, depending on what sources you will index.
- you will need at least 8G of RAM but if you will use this machine to index new sources you will need at least 20G

## Prerequisites

### Software

No other webserver should be running on this machine and no other daemon/software should be listening on the ports 80 and 443.

This command should ***not*** return anything:
```bash
netstat -tupl | grep -i http
```

update and upgrade your machine
```bash
sudo apt get update
sudo apt get upgrade
sudo apt autoremove
sudo apt autoclean
```

to make all of this work you will have to install following software 

- git
```bash
sudo apt install git 
```
- make
```bash
sudo apt install make
```
- Python3
```bash
sudo apt install python
```
- Docker
```bash
sudo apt install docker
```
to be sure that Docker is using your /data directory for it's overlays, add following to /etc/docker/daemon.js and restart docker daemon
```
{
  "data-root": "/data/docker"
}
```

```bash
service docker restart
```

#### for testing
- wget
```bash
sudo apt install wget
```
- netcat
```bash
sudo apt install netcat
```

### DNS

If you want this to be a production machine or a machine that is accessible from outside you will need to make some entries in your DNS for your domain
(replace XYZ.XYZ.XYZ.XYZ with the public ip address of your server).
```
search 10800 IN A XYZ.XYZ.XYZ.XYZ
api.search 10800 IN CNAME search
```
Check your DNS settings:
```bash
dig search.domain-name
dig api.search.domain-name
```
e.g.
```bash
dig search.oceaninfohub.org

;; QUESTION SECTION:
;search.oceaninfohub.org.	IN	A

;; ANSWER SECTION:
search.oceaninfohub.org. 1768 IN	A	193.191.134.46

dig api.search.oceaninfohub.org

;; QUESTION SECTION:
;api.search.oceaninfohub.org.	IN	A

;; ANSWER SECTION:
api.search.oceaninfohub.org. 10800 IN	CNAME	search.oceaninfohub.org.
search.oceaninfohub.org. 1768 IN	A	193.191.134.46
```

If you want to install only locally, you will need to add these two entries to the machine's hosts file 
(typically ***/etc/hosts***) (replace domain-name with the domain name of the machine):

```vim
127.0.0.1 domain-name
127.0.0.1 api.domain-name
```

### Firewall

You should change your firewall setting to allow incoming traffic:
- port 80
- port 443

Your firewall needs to allow this machine to connect to itself using the public IP address.

At this point you can test this using [netcat](https://linux.die.net/man/1/nc).
On this machine:
```bash
netcat -80
```
On another machine:
```bash
netcat domain-name 80
```
This should give you a prompt and when typing anything here, this should result in the same text appearing on the server **damain-name**.
Repeat for port 443.

### Sample data

For the search to work you will need some data that we can use.
@todo : how do people get that sample data???
Unzip the sample data file (sample-solr-data) on the machine to /tmp.

### Installation dir

We will install everything under the same directory on the server, in this README we will use ***/data*** for this.

## Installation

Some parts of the guide vary depending on whether you want to start a server locally or in production.

Follow these steps to set up the OIH UI Docker environment:

### Clone the repository with submodules

```bash

cd /data
git clone --recurse-submodules git@github.com:iodepo/oih-ui-docker.git oih-ui-docker

```

### Fetch the latest changes

```bash

cd oih-ui-docker
git fetch
git checkout release

```

### Checkout the `feature/restyling` branch

```bash

cd frontend
git fetch
git checkout feature/restyling
cd ..

```

### Create a `.env` file with the following content

copy the sample file and edit
```bash
cp env.sample .env 
vim .env
```

```env
HOST=domain-name
# (the same one you used for the hosts file or for the DNS)
```

### Insert the `sample-solr-data` folder at the path `api/solr`

Use the `sample-solr-data` file from the zip file you decompressed to /tmp earlier and give correct permissions.
```bash
mv /tmp/sample-solr-data /data/oih-ui-docker/api/solr/
chmod -R 777 /data/oih-ui-docker/api/solr/sample-solr-data
```

### Start the Docker containers

***WARNING*** depending on the version of Docker installed on your system, you will need to use either ***docker compose*** or ***docker-compose***.

#### for local installation

```bash

docker compose up -d


```

#### production installation

```bash

docker compose -f docker-compose.prod.yml up -d

```

### Initialize the Solr database

***WARNING*** depending on the version of Docker installed on your system, you will need to use either ***docker compose*** or ***docker-compose***.

#### for local installation

```bash

docker compose run -u root solr chown solr:solr /var/solr/data/ckan/data

```

#### production installation

```bash

docker compose -f docker-compose.prod.yml run -u root solr chown solr:solr /var/solr/data/ckan/data

```

### Restart the `oih-ui-docker` containers

```bash

docker restart $(docker ps -a -q)

```

### check if all is running

```bash
docker ps
```

should give you something like
```bash
CONTAINER ID   IMAGE                           COMMAND                  CREATED       STATUS             PORTS                                      NAMES
26c48d9bef42   nginxproxy/acme-companion       "/bin/bash /app/entr…"   2 hours ago   Up About an hour                                              oih-ui-docker-letsencrypt-nginx-proxy-companion-1
81317aaef610   solr:8                          "docker-entrypoint.s…"   2 hours ago   Up About an hour                                              oih-ui-docker-solr-1
b9d02d315eaf   oih-ui-docker-api               "uvicorn api.main:ap…"   2 hours ago   Up About an hour   8000/tcp                                   oih-ui-docker-api-1
dec760172936   nginxproxy/nginx-proxy:latest   "/app/docker-entrypo…"   2 hours ago   Up About an hour   0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp   oih-ui-docker-nginx-proxy-1
450034477e27   oih-ui-docker-web               "docker-entrypoint.s…"   2 hours ago   Up About an hour                                              oih-ui-docker-web-1
```

### Access the application

At this point you should be able to see the search interface and should be able to use it.

Open your browser and go to https://domain-name/ .

# trouble shooting

in the unlikely case something goes wrong, start looking at the logs of the different containers to get a clue what might be wrong.

e.g.
```bash
docker ps
CONTAINER ID   IMAGE                           COMMAND                  CREATED       STATUS             PORTS                                      NAMES
26c48d9bef42   nginxproxy/acme-companion       "/bin/bash /app/entr…"   2 hours ago   Up About an hour                                              oih-ui-docker-letsencrypt-nginx-proxy-companion-1
81317aaef610   solr:8                          "docker-entrypoint.s…"   2 hours ago   Up About an hour                                              oih-ui-docker-solr-1
b9d02d315eaf   oih-ui-docker-api               "uvicorn api.main:ap…"   2 hours ago   Up About an hour   8000/tcp                                   oih-ui-docker-api-1
dec760172936   nginxproxy/nginx-proxy:latest   "/app/docker-entrypo…"   2 hours ago   Up About an hour   0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp   oih-ui-docker-nginx-proxy-1
450034477e27   oih-ui-docker-web               "docker-entrypoint.s…"   2 hours ago   Up About an hour                                              oih-ui-docker-web-1

docker logs 450034477e27
```

## you see ***NetworkError when attempting to fetch resource.***

check the network and DNS settings, again (see higher)

- is your DNS setting correct
```bash
dig domain-name
```
e.g.
```bash
dig search.oceaninfohub.org

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;search.oceaninfohub.org.	IN	A

;; ANSWER SECTION:
search.oceaninfohub.org. 22	IN	CNAME	oih.iode.org.
oih.iode.org.		22	IN	A	193.191.134.46
```
if you do not get the correct ip address (= public ip address from the firewall if you are running a public server), check the DNS settings
- can you access the public interface
```bash
wget https://domain-name
```
e.g.
```bash
wget search.oceaninfohub.org
--2024-06-13 13:58:06--  http://search.oceaninfohub.org/
Resolving search.oceaninfohub.org (search.oceaninfohub.org)... 193.191.134.46
Connecting to search.oceaninfohub.org (search.oceaninfohub.org)|193.191.134.46|:80... connected.
HTTP request sent, awaiting response... 301 Moved Permanently
Location: https://search.oceaninfohub.org/ [following]
--2024-06-13 13:58:07--  https://search.oceaninfohub.org/
Connecting to search.oceaninfohub.org (search.oceaninfohub.org)|193.191.134.46|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 1462 (1.4K) [text/html]
Saving to: ‘index.html.2’

index.html.2                                    100%[=====================================================================================================>]   1.43K  --.-KB/s    in 0s      

2024-06-13 13:58:07 (425 MB/s) - ‘index.html.2’ saved [1462/1462]
```
If you cannot see that you have to check your firewall, you may not have the correct rights to connect to the public interface of the firewall.

## you encounter an issue with the Solr container

- check the permissions of the /data/oih-ui-docker/api/solr/sample-solr-data dir, all should be set to 777 (rwxrwxrwx)
- try deleting the write.lock file inside the sample-solr-data folder and restart the container
