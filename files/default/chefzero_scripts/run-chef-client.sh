#! /bin/bash

if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root" 2>&1
  exit 1
fi

cd /etc/chef

# Backup latest Chef node previously executed, preserving permissions and timestamp
# Chef nodes are created everytime Chef runs successfully
CHEF_NODE_NAME=`ls -lt /etc/chef/nodes | grep -v total | head -1 | awk '{print $9}'`
BACKUP_NODE_NAME=`date +"%Y%m%d%k%M"`-chef-$CHEF_NODE_NAME
mkdir -p /var/log/chef-runs
mv /etc/chef/nodes/$CHEF_NODE_NAME /var/log/chef-runs/$BACKUP_NODE_NAME
rm -rf /etc/chef/nodes/$CHEF_NODE_NAME

chef-client --local-mode -j /etc/chef/run-chef-client.json >> /var/log/chef-client.log

cd -
