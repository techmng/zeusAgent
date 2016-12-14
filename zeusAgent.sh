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
  	ubuntu_dist="$(lsb_release --codename | cut -f2)"
  else
    echo "lsb_release missing"
    exit 1
  fi
  case "$ubuntu_dist" in 
        xenial)
	curl -L http://toolbelt.treasuredata.com/sh/install-ubuntu-xenial-td-agent2.sh | sh
       ;;
       trusty)
	curl -L http://toolbelt.treasuredata.com/sh/install-ubuntu-trusty-td-agent2.sh | sh
       ;;
       precise)
        curl -L http://toolbelt.treasuredata.com/sh/install-ubuntu-precise-td-agent2.sh | sh
       ;;
       lucid)
        curl -L http://toolbelt.treasuredata.com/sh/install-ubuntu-lucid-td-agent2.sh | sh
       ;;
       wheezy)
        curl -L http://toolbelt.treasuredata.com/sh/install-debian-wheezy-td-agent2.sh | sh
       ;;
       squeeze)
        curl -L http://toolbelt.treasuredata.com/sh/install-debian-squeeze-td-agent2.sh | sh
       ;;
       *)
       echo "No Distribution detected"
       exit 1
esac
  # Fluentd Packages
  apt-get install -y gem ruby-dev
  td-agent-gem install fluent-plugin-record-reformer
  td-agent-gem install fluent-plugin-secure-forward

  # Collectd Packages
  yes | sudo add-apt-repository ppa:rullmann/collectd
  apt-get update
  apt-get install -y collectd
}

configure_agent(){
  cd /tmp
  sed -i -- "s/<YOUR USERNAME HERE>/$ZEUS_USERNAME/g" td-agent.conf
  sed -i -- "s/<YOUR TOKEN HERE>/$ZEUS_TOKEN/g" td-agent.conf
  sed -i -- "s/data03.ciscozeus.io/$INGESTION_DOMAIN/g" td-agent.conf
  cp td-agent.conf /etc/td-agent/td-agent.conf
  cp 10-rsyslog.conf /etc/rsyslog.d/10-rsyslog.conf
  cp collectd.conf /etc/collectd/collectd.conf
}

start_agent(){
  service td-agent restart
  service collectd restart
  service rsyslog restart
}

install_packages
download_configs
configure_agent
start_agent

