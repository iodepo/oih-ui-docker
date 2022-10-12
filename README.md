## Single Machine OIH install

This is a docker-compose wrapper providing all of the services for the OIH search engine on one docker-compose stack for development or staging deployment.

It includes
* nginx-proxy as a web proxy to access the website and the api
* A lets-encrypt sidecar for nginx-proxy to provide for certificates. If you are running on a local/non-internet accessible domain, this will silently fall back to HTTP rather than HTTPS.
* Container definitons for the API, web, and solr instances.

Running `make` will give a list of makefile commands of interest.


To get started:

```
si:oih-ui-docker erics$ make init
Makefile:3: .env: No such file or directory
sed: .env: No such file or directory
./make_env.py

Making the ENV file...

Hostname? oih.localhost
git submodule update --init --recursive
/Applications/Xcode.app/Contents/Developer/usr/bin/make initdb-solr
docker-compose run -u root solr chown solr:solr /var/solr/data/ckan/data
Creating oih-ui-docker_solr_run ... done
si:oih-ui-docker erics$ make up
```

At this point, the system should be up and running, though without any indexed documents.


## Settings Details

The docker compose sets some environment variables that are important for connecting between the various services.

### API

The api is assumed to be at `api.hostname`, the website at `hostname` (as set in the .env file by make_env.py) This can be changed in the environment variables `VIRTUAL_HOST` for the proxy service and `LETSENCRYPT_HOST` for the lets-encrypt ssl cert. For development work, I find it useful to map `*.localhost` to my local machine, so `oih.localhost` and `api.oih.localhost` automatically resolve to my dev machine.

If you change the API url, the setting for `REACT_APP_DATA_SERVICE_URL` in the web environment needs to be changed to match.

### Solr

The `SOLR_JAVA_MEM` setting may require tweaking to allow for more memory to be used by the solr process, depending on the machine size.
