#!/bin/bash

# get-gems.sh
#
# get-gems.sh is a Bash script that fetches Ruby gems using Bundler
# It is tested using ChefDK

# Exit at first failure
set -e

# Fixes issue https://github.com/berkshelf/berkshelf-api/issues/112
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

GEMFILE=$1

echo "[get-gems.sh] Start; using gemfile $GEMFILE"

# Locate gem executables
if [ -d '/opt/chefdk' ]
then
  export PATH=$HOME/.chefdk/gem/ruby/2.1.0/bin:/opt/chefdk/bin:/opt/chefdk/embedded/bin:$PATH
  # To avoid nasty nokogiri failures - https://github.com/chef/chef-dk/issues/278
  export PKG_CONFIG_PATH=/opt/chefdk/embedded/lib/pkgconfig
fi

export GEM_HOME=$HOME/.gemhome

# Installing gems in GEM_HOME
echo "[get-gems.sh] Running Bundler install"
bundle install --gemfile=$GEMFILE
rm -rf $GEMFILE $GEMFILE.lock
