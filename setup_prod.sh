#!/bin/bash

#define some colours
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
printf "${NC}"

helpFunction()
{
   echo ""
   echo "Usage: $0 -d installDir -s solrDir -u url"
   echo -e "\t-d complete path to where we will install everything (default /data/oih-ui-docker/)"
   echo -e "\t-s complete path to the SOLR test data (default /data/solr_data/)"
   echo -e "\t-u url of the search interface (default https://devsearch.oceaninfohub.org/)"
   echo -e "\t-h print this help"
   exit 1 # Exit script after printing help
}

while getopts "d:s:u:h" opt
do
   case "$opt" in
      d ) installDir="$OPTARG" ;;
      s ) solrDir="$OPTARG" ;;
      u ) url="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# use default values if not set
if [ -z "$installDir" ]; then
  installDir='/data/oih-ui-docker/'
  printf "using default installation directory: $installDir \n"
fi

if [ -z "$solrDir" ]; then
  solrDir='/data/solr_data/'
  printf "using default solr directory: $solrDir \n"
fi

if [ -z "$url" ]; then
  url='https://devsearch.oceaninfohub.org/'
  # shellcheck disable=SC2028
  printf "using default url: $url \n"
fi

#check the correctness of the values
#installDir must be a complete path
if [[ "$installDir" =~ ^\/[[:alnum:]] && "$installDir" =~ [[:alnum:]]\/$ ]]; then
  printf "$installDir is a valid complete path\n"
  #check if the parent directory exists
  #the directory itself will be created by GIT
  installDirParent="$(dirname "$installDir")"
  if [ -d $installDirParent ]; then
    printf "$installDirParent exists\n"
  else
    printf "${RED}ERROR${NC}: $installDirParent does not exist, we cannot create $installDir if $installDirParent does not exist\n"
    exit 6
  fi

else
  printf "${RED}ERROR${NC}: $installDir is not a valid complete path, should be something like /data/oih-ui-docker/\n"
  exit 2
fi

#solrDir must be a complete path
if [[ "$solrDir" =~ ^\/[[:alnum:]] && "$solrDir" =~ [[:alnum:]]\/$ ]]; then
  printf "$solrDir is a valid complete path\n"

  #solrDir must exist
  if [ -d $solrDir ]; then
    printf "$solrDir exists\n"
  else
    printf "${RED}ERROR${NC}: $solrDir does not exist\n"
    exit 5
  fi
else
  printf "${RED}ERROR${NC}: $solrDir is not a valid complete path, should be something like /data/solr_data/\n"
  exit 3
fi

#url must be a correct url
if [[ "$url" =~ ^https?\:\/\/([[:alnum:]]+\.)+[[:alnum:]]+\/?$ ]]; then
  printf "$url is a valid url\n"
else
  printf "${RED}ERROR${NC}: $url is not a valid url, should be something like http(s)://devsearch.oceaninfohub.org/\n"
  exit 4
fi

#clean the url, remove http(s)://
re='^https?\:\/\/(([[:alnum:]]+\.)+[[:alnum:]]+)\/?$'
if [[ $url =~ $re ]]; then
  host=${BASH_REMATCH[1]}
fi

#do we want to install the worklfow container?
printf "\nDo you want to install the workflow container (${YELLOW}Y${NC}/n):\n"
read useWorkflowContainer
if [ "$useWorkflowContainer" = "n" ] ;then
  printf "no workflow container will be installed\n"
else
  printf "workflow container will be installed\n"
  useWorkflowContainer="y"
fi

printf "\nUsage: $0 -d installDir -s solrDir -u url \n"
printf "for more info: $0 -h \n"
printf "\nare these the correct settings (${YELLOW}Y${NC}/n):\n"
printf "\tinstall dir :    $installDir\n"
printf "\tsolr test data : $solrDir\n"
printf "\turl :            $url\n"
printf "\tworkflow :       $useWorkflowContainer\n\n"

read answer4

if [ "$answer4" = "n" ] ;then
  printf "nothing will be done"
  exit 1
fi

printf "start installation\n\n"

# stop and remove old containers
printf " \n${YELLOW}stopping and removing old containers${NC}\n"
# stop running container(s)
docker ps -aq | xargs -r docker stop
# remove existing container(s)
docker ps -aq | xargs -r docker rm

# Remove all volumes (to avoid cert generation issues)
printf " \n${YELLOW}removing all volumes${NC}\n"
docker volume ls -qf dangling=true | xargs -r docker volume rm

# Remove all images
printf " \n${YELLOW}removing all images${NC}\n"
docker images -a -q | xargs -r docker rmi

# and finally, cleanup Docker
printf " \n${YELLOW}finally cleanup Docker${NC}\n"
docker system prune -f

# Clone the repository and its submodules
printf " \n${YELLOW}cloning oih-ui-docker to $installDir${NC}\n"
git clone --recurse-submodules git@github.com:iodepo/oih-ui-docker.git $installDir

# Navigate to the project directory
cd $installDir

# Fetch the latest changes and check out the 'release' branch
printf " \n${YELLOW}fetching and checking out the 'release' branch${NC}\n"
git fetch
git checkout release

# Navigate to the 'frontend' directory, fetch the latest changes, and check out the 'feature/restyling' branch
printf " \n${YELLOW}navigating to 'frontend' directory and fetching and checking out the 'feature/restyling' branch${NC}\n"
cd $installDir/frontend
git fetch
git checkout feature/restyling

# Return to the main directory and navigate to the 'api' directory, fetch the latest changes, and check out the 'feature/restyling' branch
printf " \n${YELLOW}navigating to 'api' directory and fetching and checking out the 'feature/restyling' branch${NC}\n"
cd $installDir/api
git fetch
git checkout feature/restyling

# Create the .env file in the project directory
cd $installDir
touch $installDir/.env

# Add the HOST variable to the .env file
echo "HOST=$host" > $installDir/.env

if [ "$useWorkflowContainer" = "n" ] ;then
  dockerComposeFile="docker-compose.noWorkflow.yml"
  printf "using ${YELLOW}$dockerComposeFile${NC}\n"
else
  dockerComposeFile="docker-compose.workflow.yml"

  #copy the old file and add a date to the name
  printf "make backup of ${YELLOW}letsencrypt_user_data.conf${NC}\n"
  cp $installDir/nginx/conf.d/letsencrypt_user_data.conf $installDir/nginx/conf.d/letsencrypt_user_data.conf_$(date +%Y%m%d%H%M%S)

  #add the correct lines for the SSL certificates
  #our current ip
  localIp=$(ifconfig -a | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep 192 | grep -v 255 | head -1)
  workflowHost="workflow.${host}"
  echo "LETSENCRYPT_STANDALONE_CERTS=('workflow')" >> $installDir/nginx/conf.d/letsencrypt_user_data.conf
  echo "LETSENCRYPT_workflow_HOST=('$workflowHost')" >> $installDir/nginx/conf.d/letsencrypt_user_data.conf

  #copy the old proxy file and add a date to the name
  printf "make backup of ${YELLOW}proxy.conf${NC}\n"
  cp $installDir/nginx/conf.d/proxy.conf $installDir/nginx/conf.d/proxy.conf_$(date +%Y%m%d%H%M%S)

  #add the correct lines for the nginx proxy
  echo "server {" >> $installDir/nginx/conf.d/proxy.conf
  echo "    server_name $workflowHost;" >> $installDir/nginx/conf.d/proxy.conf
  echo "    listen 80;" >> $installDir/nginx/conf.d/proxy.conf
  echo "    access_log /var/log/nginx/workflow.search.log vhost;" >> $installDir/nginx/conf.d/proxy.conf;
  echo "    location / {" >> $installDir/nginx/conf.d/proxy.conf
  echo "        proxy_pass          http://$localIp:3000;" >> $installDir/nginx/conf.d/proxy.conf;
  echo "    }" >> $installDir/nginx/conf.d/proxy.conf
  echo "}" >> $installDir/nginx/conf.d/proxy.conf

  printf "using ${YELLOW}$dockerComposeFile${NC}\n"
  printf "access workflow via ${YELLOW}https://$workflowHost${NC}\n"

  #copy the old .env file and add a date to the name
  cp $installDir/.env $installDir/.env_$(date +%Y%m%d%H%M%S)

  #change the .env file, add some lines for the workflow container
  echo "#settings for the workflow" >> $installDir/.env
  echo "PROJECT=eco" >> $installDir/.env
  echo "GLEANERIO_GLEANER_IMAGE=nsfearthcube/gleaner:dev_ec" >> $installDir/.env
  echo "GLEANERIO_NABU_IMAGE=nsfearthcube/nabu:dev_eco" >> $installDir/.env
  echo "GLEANERIO_GLEANER_CONFIG_PATH=/gleaner/gleanerconfig.yaml" >> $installDir/.env
  echo "GLEANERIO_NABU_CONFIG_PATH=/nabu/nabuconfig.yaml" >> $installDir/.env
  echo "GLEANERIO_LOG_PREFIX=scheduler/logs/" >> $installDir/.env
  echo "GLEANERIO_MINIO_ADDRESS=ossapi.provisium.io" >> $installDir/.env
  echo "GLEANERIO_MINIO_PORT=" >> $installDir/.env
  echo "GLEANERIO_MINIO_USE_SSL=true" >> $installDir/.env
  echo "GLEANERIO_MINIO_BUCKET=gleaner" >> $installDir/.env
  echo "GLEANERIO_MINIO_ACCESS_KEY=minioadmin" >> $installDir/.env
  echo "GLEANERIO_MINIO_SECRET_KEY=6EcDLmMiXsAPjc9kttAE7PMXitxrnyqxEefCYPoy" >> $installDir/.env
  echo "GLEANERIO_HEADLESS_ENDPOINT=http://workstation.lan:9222" >> $installDir/.env
  echo "GLEANERIO_GRAPH_URL=http://nas.lan:49153/blazegraph" >> $installDir/.env
  echo "GLEANERIO_GRAPH_NAMESPACE=earthcube" >> $installDir/.env

fi


# Copy Solr data to the target directory and change its permissions (change the root with the right one)
printf " \n${YELLOW}copying Solr data to the target directory and changing its permissions${NC}\n"
cp -r $solrDir $installDir/api/solr/sample-solr-data/
chmod -R 777 $installDir/api/solr/sample-solr-data/

# Start the Docker containers in production mode
printf " \n${YELLOW}starting the Docker containers in production mode${NC}\n"
docker compose -f $dockerComposeFile up -d --remove-orphans

# Wait for 10 seconds before continue
printf " \n${YELLOW}sleep for 10s${NC}\n"
sleep 10 &
  PID=$!
  i=1
  sp="/-\|"
  echo -n ' '
  while [ -d /proc/$PID ]
  do
    printf "\b${sp:i++%${#sp}:1}"
  done

#erase the progress bar
echo -ne "\r\033[K"

# Change permissions for the Solr directory
printf " \n${YELLOW}changing permissions for the Solr directory${NC}\n"
docker compose -f $dockerComposeFile run -u root solr chown solr:solr /var/solr/data/ckan/data

# Restart the containers
printf " \n${YELLOW}restarting the containers${NC}\n"
docker restart $(docker ps -a -q)

printf " \n${YELLOW}sleep for 30s${NC}\n"
sleep 30 &
PID=$!
i=1
sp="/-\|"
echo -n ' '
while [ -d /proc/$PID ]
do
  printf "\b${sp:i++%${#sp}:1}"
done

#erase the progress bar
echo -ne "\r\033[K"

#get the certifcates from the Letsencrypt container
printf " \n${YELLOW}restart the Let's encrypt container${NC}\n"
docker restart oih-ui-docker-letsencrypt-nginx-proxy-companion-1
printf " \n${YELLOW}sleep for 20s${NC}\n"
sleep 20 &
  PID=$!
  i=1
  sp="/-\|"
  echo -n ' '
  while [ -d /proc/$PID ]
  do
    printf "\b${sp:i++%${#sp}:1}"
  done

#erase the progress bar
echo -ne "\r\033[K"

#restart the nginx-proxy and web containers
printf " \n${YELLOW}restart the nginx-proxy and web containers${NC}\n"
docker restart oih-ui-docker-nginx-proxy-1
printf " \n${YELLOW}sleep for 20s${NC}\n"
sleep 20 &
  PID=$!
  i=1
  sp="/-\|"
  echo -n ' '
  while [ -d /proc/$PID ]
  do
    printf "\b${sp:i++%${#sp}:1}"
  done

#erase the progress bar
echo -ne "\r\033[K"

docker restart oih-ui-docker-web-1
printf " \n${YELLOW}sleep for 40s${NC}\n"
sleep 40 &
  PID=$!
  i=1
  sp="/-\|"
  echo -n ' '
  while [ -d /proc/$PID ]
  do
    printf "\b${sp:i++%${#sp}:1}"
  done

#erase the progress bar
echo -ne "\r\033[K"

#these dockers are running
printf " \n${YELLOW}these dockers are running now${NC}\n"
docker ps

# Print a success message
printf " \n${YELLOW}Installation completed successfully! All should be available soon on $url ${NC}\n"

