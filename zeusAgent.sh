#!/bin/bash
set -o errexit
 
ZEUS_USERNAME=$1 
ZEUS_TOKEN=$2
INGESTION_DOMAIN=$3
TD_AGENT_URL=https://ciscozeus.io/td-agent.conf
RSYSLOG_URL=https://ciscozeus.io/10-rsyslog.conf
COLLECTD_URL=https://ciscozeus.io/collectd.conf 

if [[ -z $ZEUS_USERNAME ]] || [[ -z $ZEUS_TOKEN ]] || [[ -z $INGESTION_DOMAIN ]] ; then
    echo "./zeusAgent <ZEUS_USERNAME> <ZEUS_TOKEN> <INGESTION_DOMAIN>"
    exit 1
fi 

command_exists(){
  command -v "$1" >/dev/null 2>&1
}

download_configs(){
  cd /tmp
  curl -O $TD_AGENT_URL
  curl -O $RSYSLOG_URL
  curl -O $COLLECTD_URL
}

install_packages() {
  if command_exists lsb_release; then
  	os_dist="$(lsb_release --codename | cut -f2)"
  else 
       yum provides */lsb_release
       yum install -y redhat-lsb-core
       os_dist="$(lsb_release --id | cut -f2)"
  fi  
  case "$os_dist" in 
        xenial)
	curl -L http://toolbelt.treasuredata.com/sh/install-ubuntu-xenial-td-agent2.sh | sh
       ;;
       trusty)
	curl -L http://toolbelt.treasuredata.com/sh/install-ubuntu-trusty-td-agent2.sh | sh
        yes | sudo add-apt-repository ppa:rullmann/collectd
       ;;
       precise)
        curl -L http://toolbelt.treasuredata.com/sh/install-ubuntu-precise-td-agent2.sh | sh
        yes | sudo add-apt-repository ppa:rullmann/collectd
       ;;
       jessie)
        apt-get install -y curl
        curl -L https://toolbelt.treasuredata.com/sh/install-debian-jessie-td-agent2.sh | sh
       ;;
       wheezy)
        apt-get install -y curl
        curl -L http://toolbelt.treasuredata.com/sh/install-debian-wheezy-td-agent2.sh | sh
       ;;
       CentOS)
        curl -L http://toolbelt.treasuredata.com/sh/install-redhat-td-agent2.sh | sh
        ;;
       *)
        echo "OS Distribution Not supported"
        exit 1
esac
  # td-agent and collectd dependencies
  if [[ "$os_dist" != "CentOS" ]]; then 
    apt-get install -y gem ruby-dev
    apt-get install -y collectd
    apt-get update
  else
    yum install -y ruby-devel rubygems
    yum install -y collectd collectd-rrdtool
  fi
  # td-agent plugins
  td-agent-gem install fluent-plugin-record-reformer
  td-agent-gem install fluent-plugin-secure-forward
}

configure_agent(){
  cd /tmp
  sed -i -- "s/<YOUR USERNAME HERE>/$ZEUS_USERNAME/g" td-agent.conf
  sed -i -- "s/<YOUR TOKEN HERE>/$ZEUS_TOKEN/g" td-agent.conf
  sed -i -- "s/data03.ciscozeus.io/$INGESTION_DOMAIN/g" td-agent.conf
  cp td-agent.conf /etc/td-agent/td-agent.conf
  cp 10-rsyslog.conf /etc/rsyslog.d/10-rsyslog.conf

  os_dist="$(lsb_release --id | cut -f2)"
  if [[ "$os_dist" == "CentOS" ]]; then
    cp collectd.conf /etc/collectd.conf
  else 
    cp collectd.conf /etc/collectd/collectd.conf
  fi
}

start_agent(){
  service rsyslog restart 
  service td-agent restart
  service collectd restart
}

install_packages
download_configs
configure_agent
start_agent
