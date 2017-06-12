#!/bin/bash

# release-cookbook.sh
#
# release-cookbook.sh is a Bash script runs a Chef cookbook release (if you pass `release` as first command-line param), performing the following steps:
# 1. Parse GIT_REPO URL (TODO only https urls are supported, no support yet for ssh endpoints) to extract the name of the repository
# 2. Creates a tag with the git master branch
# 3. Builds a tar.gz artifact using `berks package` command (more on http://berkshelf.com/)
# 4. Pushes artifact built by #2 into a remote artifact repository (currently only Sonatype Nexus is supported)
# 5. (Optionally) invokes Packer to build an image with the current definition (TODO)
# 6. Pushes git tag remotely (or remove it, if there was any error on steps #3 to #5)
# 7. Increments the version of metadata.rb, pushing the change to master
# For more details, check `function release` below
#
# release-cookbook.sh can also deploy nightly builds and it's default action of this script (if no parameters are passed).
#
# The script can be invoked with the following syntax:
#
# curl -L https://raw.githubusercontent.com/Alfresco/chef-commons/master/release-cookbook.sh --no-sessionid | bash -s
#
# The following variables must be set before running:
#
# The Git repository where the Chef cookbook is located
# export GIT_REPO=${bamboo.planRepository.repositoryUrl}
#
# The Maven Repository URL used to deploy cookbook tar.gz
# export MVN_REPO_URL=https://my.nexus.com/nexus/content/repositories/private
#
# The Maven Repository ID as defined by Maven settings.xml
# export MVN_REPO_ID=my-mvn-repo-id
#
# The GIT HTTP token used for changelog generation (TODO - is this really needed?)
# export GIT_TOKEN=blablablabla
#
# The following variables can be overridden (default values are mentioned below)
#
# export GROUP_ID=my.acme.project
# export PACKER_BIN=packer
# export PACKER_TEMPLATE=my-packer-template.json
# export PACKER_OPTS=""
# export CHANGELOG_BIN=github_changelog_generator
# export GIT_PREFIX=git@github.com
# export GIT_ACCOUNT_NAME=`echo ${GIT_REPO%????} | cut -d "/" -f 4`

# Exit at first failure
set -e

# Fixes issue https://github.com/berkshelf/berkshelf-api/issues/112
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Generate Gemfile, containing all gems used below for linting and testing
echo "[test-cookbook.sh] Creating GemfileTemp for release run"

cat <<EOF > GemfileTemp
source 'https://rubygems.org'

gem 'berkshelf'
gem 'github_changelog_generator'
EOF

curl -L https://raw.githubusercontent.com/Alfresco/chef-commons/master/scripts/get-gems.sh --no-sessionid | bash -s -- ./GemfileTemp

if [ -z "$GIT_REPO" ] || [ -z "$MVN_REPO_URL" ] || [ -z "$MVN_REPO_ID" ] ; then
  echo "[release-cookbook.sh] One of the mandatory variables is not set: GIT_REPO, MVN_REPO_URL, MVN_REPO_ID. Aborting."
  exit
else
  echo "[release-cookbook.sh] GIT_REPO=$GIT_REPO"
  echo "[release-cookbook.sh] MVN_REPO_URL=$MVN_REPO_URL"
  echo "[release-cookbook.sh] MVN_REPO_CREDS_ID=$MVN_REPO_ID"
fi

# If ARTIFACT_ID is not set, extract it from GIT_REPO
# Right now it only supports HTTP Git urls
if [ -z "$ARTIFACT_ID" ]; then
  export ARTIFACT_ID=`echo ${GIT_REPO%????} | cut -d "/" -f 5`
  echo "[release-cookbook.sh] Setting ARTIFACT_ID=$ARTIFACT_ID"
else
  echo "[release-cookbook.sh] ARTIFACT_ID=$ARTIFACT_ID"
fi

if [ -z "$GIT_PROJECT_NAME" ]; then
  export GIT_PROJECT_NAME=$ARTIFACT_ID
  echo "[release-cookbook.sh] Setting GIT_PROJECT_NAME=$ARTIFACT_ID"
else
  echo "[release-cookbook.sh] GIT_PROJECT_NAME=$ARTIFACT_ID"
fi

if [ -z "$PACKER_BIN" ]; then
  export PACKER_BIN=/usr/local/packer/packer
fi

if [ -z "$CHANGELOG_BIN" ]; then
  export CHANGELOG_BIN=github_changelog_generator
fi

if [ -z "$MVN_BIN" ]; then
  export MVN_BIN=/opt/apache-maven/bin/mvn
fi

if [ -z "$GIT_BIN" ]; then
  export GIT_BIN=git
fi

if [ -z "$GIT_BIN" ]; then
  export GIT_BIN=git
fi

if [ -z "$GIT_PREFIX" ]; then
  export GIT_PREFIX=git@github.com
fi

if [ -z "$GIT_ACCOUNT_NAME" ]; then
  export GIT_ACCOUNT_NAME=`echo ${GIT_REPO%????} | cut -d "/" -f 4`
fi

echo "[release-cookbook.sh] Setting git remote to $GIT_PREFIX:$GIT_ACCOUNT_NAME/$GIT_PROJECT_NAME.git"
git remote set-url origin $GIT_PREFIX:$GIT_ACCOUNT_NAME/$GIT_PROJECT_NAME.git

# Version-specific functions

function getCurrentVersion () {
  version=`cat metadata.rb| grep -w version|awk '{print $2}' | tr -d \"`
  echo $version
}

function getIncrementedVersion () {
  version=$(getCurrentVersion)
  echo $version | awk -F'[.]' '{print $1 "." $2 "." $3+1}'
}

function incrementVersion () {
  $GIT_BIN pull origin master

  export currentVersion=$(getCurrentVersion)
  export nextVersion=$(getIncrementedVersion)

  echo "[release-cookbook.sh] Incrementing version from $currentVersion to $nextVersion"

  sed "s/$currentVersion/$nextVersion/" metadata.rb > metadata.rb.tmp
  rm -f metadata.rb
  mv metadata.rb.tmp metadata.rb

  if [ -n "$GIT_TOKEN" ]
  then
    echo "[release-cookbook.sh] Adding $currentVersion to CHANGELOG.md"
    $CHANGELOG_BIN -u $GIT_ACCOUNT_NAME -p $GIT_PROJECT_NAME -t $GIT_TOKEN
    sed -i '/- Update /d' ./CHANGELOG.md
  fi

  echo "[release-cookbook.sh] Set new version ($(getCurrentVersion)) in metadata.rb"
  $GIT_BIN add metadata.rb
  $GIT_BIN add *.md
  $GIT_BIN commit -m "Bumping version to v$(getCurrentVersion)"
  $GIT_BIN push origin master
  echo "[release-cookbook.sh] Git push completed"
}

# Lifecycle-specific functions

function testArtifact () {
  # Invoking run-test.sh to install gems and run all checks
  curl -L https://raw.githubusercontent.com/Alfresco/chef-commons/master/scripts/test-cookbook.sh --no-sessionid | bash -s
}

function buildArtifact () {
  if [ -s Berksfile ]; then
    echo "[release-cookbook.sh] Building Chef artifact with Berkshelf"
    rm -rf Berksfile.lock *.tar.gz; berks package berks-cookbooks.tar.gz
  elif [ -d data_bags ]; then
    echo "[release-cookbook.sh] Building Chef Databags artifact"
    rm -rf *.tar.gz; tar cfvz alfresco-databags.tar.gz ./data_bags
  fi
}

function deploy () {
  echo "[release-cookbook.sh] Deploy $1"
  repo_name=$MVN_REPO_ID

  $MVN_BIN deploy:deploy-file -Dfile=$(echo *.tar.gz) -DrepositoryId=$MVN_REPO_CREDS_ID -Durl=$MVN_REPO_URL -DgroupId=$GROUP_ID  -DartifactId=$ARTIFACT_ID -Dversion=$1 -Dpackaging=tar.gz
}

# TODO - integrate with SPK, somehow
function runPacker () {
  if [ -n "$PACKER_TEMPLATE" ]
  then
    echo "[release-cookbook.sh] invoking Packer"
    $PACKER_BIN build $PACKER_TEMPLATE $PACKER_OPTS
    echo "[release-cookbook.sh] Packer completed!"
  fi
}

# Git-specific functions

function gitPrepareTag () {
  export VERSION=$(getCurrentVersion)

  echo "[release-cookbook.sh] Check if there's an old tag to remove"
  if $GIT_BIN tag -d "v$(getCurrentVersion)"
  then echo "Forced removal of local tag v$(getCurrentVersion)"
  fi

  echo "[release-cookbook.sh] Tagging to $(getCurrentVersion)"
  $GIT_BIN tag -a "v$(getCurrentVersion)" -m "releasing v$(getCurrentVersion)"
}

function gitPushTag () {
  echo "[release-cookbook.sh] Pushing $(getCurrentVersion) tag to github (origin)"
  $GIT_BIN push origin --tags
}

# First-level functions

function deployNightlyBuild () {
  echo "[release-cookbook.sh] deploy snapshot disabled"
  buildArtifact
  current_version=$(getCurrentVersion)
  deploy "$current_version-SNAPSHOT"
}

function release () {
  gitPrepareTag
  runPacker
  testArtifact
  buildArtifact
  deploy $(getCurrentVersion)
  gitPushTag
  incrementVersion
  echo "[release-cookbook.sh] Release completed!"
}

function rollbackTag () {
  if $GIT_BIN tag -d "v$(getCurrentVersion)"
    then echo "[release-cookbook.sh] Removed local tag v$(getCurrentVersion)"
  fi
}

MODE=$1
if [ "$MODE" == "release" ]; then
  release || rollbackTag
else
  deployNightlyBuild
fi
