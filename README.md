![Logo](https://oceaninfohub.org/wp-content/uploads/2020/12/logo_OIH_PNG-RGB-1.png)

# Setup Instructions for OIH UI Docker

## Prerequisites

Install:

- Docker

- Make

- Python

## Installation

Some parts of the guide vary depending on whether you want to start a server locally or in production.

For example:

If you want to install locally, you will need to add these two entries to the computer's hosts file:

- 127.0.0.1 domain-name
- 127.0.0.1 api.domain-name

However, if you want to install in production, you will need to define a DNS for the chosen domain name.

Follow these steps to set up the OIH UI Docker environment:

1.  **Decompress the provided zip file:**

Unzip the provided file. Inside, you will find the `sample-solr-data` folder needed for the installation.

2.  **Clone the repository with submodules:**

```bash

git clone --recurse-submodules git@github.com:iodepo/oih-ui-docker.git oih-ui-docker

```

3.  **Fetch the latest changes:**

```bash

cd oih-ui-docker
git fetch
git checkout release

```

4.  **Checkout the `feature/restyling` branch:**

```bash

cd frontend
git fetch
git checkout feature/restyling
cd ..

```

5.  **Create a `.env` file with the following content:**

```env

HOST=domain-name
# (the same one you used for the hosts file or for the DNS)

```

6.  **Insert the `sample-solr-data` folder at the path `api/solr`:**

Use the `sample-solr-data` file from the decompressed zip.

7.  **Start the Docker containers:**

Be careful, depending on the version of Docker installed on your system, you will need to use either docker compose or docker-compose.

If you want to create a local instance:

```bash

docker compose up -d


```

If you want to create a production instance:

```bash

docker compose -f docker-compose.prod.yml up -d

```

8.  **Initialize the Solr database:**

Be careful, depending on the version of Docker installed on your system, you will need to use either docker compose or docker-compose.

If you want to create a local instance:

```bash

make initdb-solr

```

If you want to create a production instance:

```bash

docker compose -f docker-compose.prod.yml run -u root solr chown solr:solr /var/solr/data/ckan/data

```

9.  **Restart the `oih-ui-docker` container:**

```bash

docker restart $(docker ps -a -q)

```

10. **Access the application:**

Open your browser and go to http://domain-name/ or http://domain-name/ .

If you encounter an issue with the Solr container, try deleting the write.lock file inside the sample-solr-data folder and restart the container.
