.PHONY: init help core down up logs logs-web logs-api logs-solr logs-nginx logs-le initdb-solr update-images nginx-restart

include .env
export $(shell sed 's/=.*//' .env)

help:
	@echo "Help: "
	@echo "init: submodule initialization and updates"
	@echo "down: brings the docker-compose set down "
	@echo "up: brings the docker-compose set up "
	@echo "logs | logs-web: tails webserver logs "
	@echo "logs-solr: tails solr logs "
	@echo "logs-api: tails api logs "
	@echo "logs-nginx: tails nginx logs "
	@echo "logs-le: tails nginx lets-encrypt "
	@echo "initdb-solr: prepares the solr database "

init: .env
	git submodule update --init --recursive
	$(MAKE) initdb-solr

core: update-images

down:
	docker-compose down

up:
	docker-compose up -d

logs:
	docker-compose logs -f --tail=100 web

logs-web:
	docker-compose logs -f --tail=100 web

logs-solr:
	docker-compose logs -f --tail=100 solr

logs-api:
	docker-compose logs -f --tail=100 api

logs-nginx:
	docker-compose logs -f --tail=100 nginx-proxy

logs-le:
	docker-compose logs -f --tail=100 letsencrypt-nginx-proxy-companion


.env:
	./make_env.py

install-docker-service:
	$(shell [ -e /etc/systemd/system/docker-compose.service ] || sudo cp etc/docker-compose.service /etc/systemd/system/docker-compose.service)
	sudo systemctl enable docker-compose.service


initdb-solr:
	docker-compose run -u root solr chown solr:solr /var/solr/data/ckan/data


update-images:
	grep -q "repository.staging.derilinx.com" ~/.docker/config.json || docker login "repository.staging.derilinx.com"
	docker-compose pull


nginx-restart:
	docker-compose exec nginx-proxy nginx -s reload

