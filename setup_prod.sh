#!/bin/bash

# Clone the repository and its submodules
git clone --recurse-submodules git@github.com:iodepo/oih-ui-docker.git oih-ui-docker

# Navigate to the project directory
cd oih-ui-docker

# Fetch the latest changes and check out the 'release' branch
git fetch
git checkout release

# Navigate to the 'frontend' directory, fetch the latest changes, and check out the 'feature/restyling' branch
cd frontend
git fetch
git checkout feature/restyling

# Return to the main directory and navigate to the 'api' directory, fetch the latest changes, and check out the 'feature/restyling' branch
cd ..
cd api
git fetch
git checkout feature/restyling

# Return to the main directory
cd ..

# Create the .env file by copying the env.sample file
cp env.sample .env

# Clear the content of the .env file before writing
> .env

# Add the HOST variable to the .env file
echo "HOST=$1" >> .env

# Copy Solr data to the target directory and change its permissions (change the root with the right one)
cp -r /data/solr_data /data/oih-ui-docker/api/solr/sample-solr-data/
chmod -R 777 /data/oih-ui-docker/api/solr/sample-solr-data/

# Remove old containers
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)

# Remove Let's encrypt data (to avoid cert generation issues)
docker volume rm oih-ui-docker_le-data

# Start the Docker containers in production mode
docker compose -f docker-compose.prod.yml up -d

# Wait for 10 seconds before continue
sleep 10

# Change permissions for the Solr directory
docker compose -f docker-compose.prod.yml run -u root solr chown solr:solr /var/solr/data/ckan/data



docker restart $(docker ps -a -q)

echo "Sleep for 30s"
sleep 30

docker restart oih-ui-docker-letsencrypt-nginx-proxy-companion-1
echo "Restart Acme Container, Sleep for 20s"
sleep 20

docker restart oih-ui-docker-nginx-proxy-1
echo "Restart Proxy Container, Sleep for 20s"
sleep 20

docker restart oih-ui-docker-web-1
echo "Restart Web Container, Sleep for 40s"
sleep 40

echo "Script completed successfully! The container web is starting and it will be available soon"
