#!/bin/bash
set -o errexit
 
ZEUS_USERNAME=$1 
ZEUS_TOKEN=$2
INGESTION_DOMAIN=$3

#UBUNTU_DISTRO = 
if [[ -z $ZEUS_USERNAME ]] || [[ -z $ZEUS_TOKEN ]] || [[ -z $INGESTION_DOMAIN ]] ; then
    echo "./zeusAgent <ZEUS_USERNAME> <ZEUS_TOKEN> <INGESTION_DOMAIN>"
fi 

if [[ -z $ZEUS_USERNAME ]]; then
  echo "Zeus Username Missing"
fi

if [[ -z $ZEUS_TOKEN ]]; then
  echo "Zeus Token Missing"
fi

if [[ -z $INGESTION_DOMAIN ]]; then
  echo "Ingestion Domain Missing"
fi

command_exists(){
  command -v "$@" >> /dev/null 2>&1
}

get_ubuntu_distro(){

}

install_packages() {
}
