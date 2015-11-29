#!/bin/bash

# This script downloads Berkshelf tar.gz files from Alfresco Internal Artifact repo
# and unpacks them into /etc/chef/[cookbooks|data_bags]

# By convention, each package identified by coordinates passed
# as parameter will either include a sub-folder called cookbooks or data_bags;
# as such all artifact's contents will be merged into the 2 mentioned folder
# contained in /etc/chef
#
# In case of file conflics, last wins.
#

if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root" 2>&1
  exit 1
fi

if [ "$#" -ne 3 ]; then
    echo "Usage: /usr/local/bin/berkshelf-checkout.sh <nexus_user> <nexus_pwd> berks1artifact_berks1version,berksNartifact_berksNversion"
    exit 1
fi

NEXUS_USER=$1
NEXUS_PWD=$2
CREDENTIALS=$1:$2

GROUP_ID="org/alfresco/devops"
NEXUS_URL_PREFIX="https://artifacts.alfresco.com/nexus/content/groups/internal"

cd /tmp
rm -rf cookbooks data_bags

IFS=',' read -a array <<< "$3"
for artifact in "${array[@]}"
do

  IFS='_' read -a artifact_coords <<< "$artifact"

  ARTIFACT_ID=${artifact_coords[0]}
  VERSION=${artifact_coords[1]}
  SNAPSHOT=${artifact_coords[2]}

  NEXUS_URL="$NEXUS_URL_PREFIX/$GROUP_ID/$ARTIFACT_ID"

  VERSION_PATH=$VERSION
  if [ "$SNAPSHOT" == "SNAPSHOT" ]; then
    VERSION_PATH="$VERSION-SNAPSHOT"

    wget --user $NEXUS_USER --password $NEXUS_PWD $NEXUS_URL/$VERSION_PATH -O nexus-artifacts.tmp
    echo "cat nexus-artifacts.tmp | grep "$NEXUS_URL" | grep "tar.gz" | grep -v "md5\|sha1" > nexus-snapshot.tmp"
    cat nexus-artifacts.tmp | grep "$NEXUS_URL" | grep "tar.gz" | grep -v "md5\|sha1" > nexus-snapshot.tmp
    VERSION=`sed "s/.*$ARTIFACT_ID-\(.*\).tar.gz.*/\1/" nexus-snapshot.tmp | sort -r | head -n 1`
    echo "Final snapshot version is $VERSION"
  fi

  NEXUS_URL="$NEXUS_URL/$VERSION_PATH/$ARTIFACT_ID-$VERSION.tar.gz"

  curl -u$CREDENTIALS $NEXUS_URL > $ARTIFACT_ID-$VERSION.tar.gz

  tar xvzf $ARTIFACT_ID-$VERSION.tar.gz
done

rm -rf /etc/chef/cookbooks /etc/chef/data_bags

cp -rf cookbooks /etc/chef
cp -rf data_bags /etc/chef
