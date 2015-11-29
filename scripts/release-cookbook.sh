#!/bin/bash

# Variables to define before invoking release.sh
# export GIT_REPO=${bamboo.planRepository.repositoryUrl}
# export MVN_REPO_ID=my-repo-id
# export MVN_REPO_CREDS_ID=my-repo-credentials-id
# export MVN_REPO_URL=http://artifacts.acme.com/nexus
# export GROUP_ID=my.acme.project

# Optional variables
# export SKIP_PACKER=true
# export GIT_TOKEN=blablablabla

# Exit at first failure
set -e

echo "[run-release.sh] MVN_REPO_CREDS_ID=$MVN_REPO_CREDS_ID"
echo "[run-release.sh] MVN_REPO_ID=$MVN_REPO_ID"

# If ARTIFACT_ID is not set, extract it from GIT_REPO
# Right now it only supports HTTP Git urls
if [ -z "$ARTIFACT_ID" ]; then
  export ARTIFACT_ID=`echo ${GIT_REPO%????} | cut -d "/" -f 5`
  echo "[run-release.sh] Setting ARTIFACT_ID=$ARTIFACT_ID"
else
  echo "[run-release.sh] ARTIFACT_ID=$ARTIFACT_ID"
fi

if [ -z "$GIT_PROJECT_NAME" ]; then
  export GIT_PROJECT_NAME=$ARTIFACT_ID
  echo "[run-release.sh] Setting GIT_PROJECT_NAME=$ARTIFACT_ID"
else
  echo "[run-release.sh] GIT_PROJECT_NAME=$ARTIFACT_ID"
fi

export GIT_PREFIX=git@github.com
export GIT_ACCOUNT_NAME=`echo ${GIT_REPO%????} | cut -d "/" -f 4`

export PATH=/usr/local/packer:/opt/apache-maven/bin:/Users/Shared/apache-maven/3.2.3/bin:$HOME/.chefdk/gem/ruby/2.1.0/bin:/opt/chefdk/bin:/opt/chefdk/embedded/bin:$PATH

echo "[run-release.sh] Setting git remote to $GIT_PREFIX:$GIT_ACCOUNT_NAME/$GIT_PROJECT_NAME.git"
git remote set-url origin $GIT_PREFIX:$GIT_ACCOUNT_NAME/$GIT_PROJECT_NAME.git

# Fixes issue https://github.com/berkshelf/berkshelf-api/issues/112
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Creates gems.list
# gem list > gems.list

# Need this gem to create CHANGELOG.md
# if grep -L github_changelog_generator gems.list; then
# PKG_CONFIG_PATH=/opt/chefdk/embedded/lib/pkgconfig gem install nokogiri
# gem install github_changelog_generator
# fi

function runTests () {
  echo "[run-release.sh] Running Chef, Foodcritic and ERB syntax check tests"
  if grep -L foodcritic gems.list; then
    gem install foodcritic
  fi
  if grep -L berkshelf gems.list; then
    gem install berkshelf
  fi
  if grep -L rails-erb-check gems.list; then
    gem install rails-erb-check
  fi
  if grep -L jsonlint gems.list; then
    gem install jsonlint
  fi
  if grep -L rubocop gems.list; then
    gem install rubocop
  fi
  #if grep -L yaml-lint gems.list; then
    gem install yaml-lint
  #fi

  find . -name "*.erb" -exec rails-erb-check {} \;
  find . -name "*.json" -exec jsonlint {} \;
  find . -name "*.rb" -exec ruby -c {} \;
  find . -name "*.yml" -not -path "./.kitchen.yml" -exec yaml-lint {} \;
  knife cookbook test cookbook -o ./ -a
  foodcritic -f any .
  # Next one should use warning as fail-level, printing only the progress review
  rubocop --fail-level warn | sed -n 2p
  rm -rf gems.list
}

function buildArtifact () {
  # Invoking run-test.sh to install gems and run all checks
  # runTests
  curl -L https://raw.githubusercontent.com/Alfresco/packer-common/master/run-test.sh --no-sessionid | bash -s

  if [ -s Berksfile ]; then
    echo "[run-release.sh] Building Chef artifact with Berkshelf"
    rm -rf Berksfile.lock *.tar.gz; berks package berks-cookbooks.tar.gz
  elif [ -d data_bags ]; then
    echo "[run-release.sh] Building Chef Databags artifact"
    rm -rf *.tar.gz; tar cfvz alfresco-databags.tar.gz ./data_bags
  fi
  # old implementation
  # /opt/chefdk/embedded/bin/rake
}

function getCurrentVersion () {
  version=`cat metadata.rb| grep version|awk '{print $2}' | tr -d \"`
  echo $version
}

function getIncrementedVersion () {
  version=$(getCurrentVersion)
  echo $version | awk -F'[.]' '{print $1 "." $2 "." $3+1}'
}

function incrementVersion () {
  export currentVersion=$(getCurrentVersion)
  export nextVersion=$(getIncrementedVersion)

  echo "[run-release.sh] Incrementing version from $currentVersion to $nextVersion"

  sed "s/$currentVersion/$nextVersion/" metadata.rb > metadata.rb.tmp
  rm -f metadata.rb
  mv metadata.rb.tmp metadata.rb

  # TODO - enable it when autoconf is installed
  if [ -n "$GIT_TOKEN" ]
  then
    echo "[run-release.sh] Adding $currentVersion to CHANGELOG.md"
    github_changelog_generator -u Alfresco -p chef-alfresco -t $GIT_TOKEN
    sed -i '/- Update /d' ./CHANGELOG.md
  fi
}

function deploy () {
  echo "[run-release.sh] Deploy $1"
  repo_name=$MVN_REPO_ID

  mvn deploy:deploy-file -Dfile=$(echo *.tar.gz) -DrepositoryId=$MVN_REPO_CREDS_ID -Durl=$MVN_REPO_URL/content/repositories/$repo_name -DgroupId=$GROUP_ID  -DartifactId=$ARTIFACT_ID -Dversion=$1 -Dpackaging=tar.gz
}

function deploySnapshot () {
  echo "[run-release.sh] deploy snapshot disabled"
  buildArtifact
  current_version=$(getCurrentVersion)
  deploy "$current_version-SNAPSHOT"
}

function release () {
  export VERSION=$(getCurrentVersion)

  echo "[run-release.sh] Check if there's an old tag to remove"
  if git tag -d "v$(getCurrentVersion)"
  then echo "Forced removal of local tag v$(getCurrentVersion)"
  fi

  echo "[run-release.sh] Tagging to $(getCurrentVersion)"
  git tag -a "v$(getCurrentVersion)" -m "releasing v$(getCurrentVersion)"

  echo "[run-release.sh] invoking Packer"
  if [ ! "$SKIP_PACKER" = true ] ; then
    curl -L https://raw.githubusercontent.com/Alfresco/packer-common/master/run-packer.sh --no-sessionid | bash -s -- ./ami.env
    echo "[run-release.sh] Packer completed!"
  fi
  buildArtifact
  deploy $(getCurrentVersion)
  echo "[run-release.sh] Pushing $(getCurrentVersion) tag to github (origin)"
  git push origin --tags
  incrementVersion
  echo "[run-release.sh] Set new version ($(getCurrentVersion)) in metadata.rb"
  git stash
  git pull origin master
  git stash pop
  git add metadata.rb
  git add *.md
  git commit -m "Bumping version to v$(getCurrentVersion)"
  git push origin master
  echo "[run-release.sh] Release completed!"
}

MODE=$1

if [ "$MODE" == "snapshot" ]; then
  deploySnapshot
else
  release
fi
