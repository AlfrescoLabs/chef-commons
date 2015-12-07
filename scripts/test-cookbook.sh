#!/bin/bash

# test-cookbook.sh
#
# test-cookbook.sh is a Bash script that runs lint checks on a project; if a ./recipes folder is found
# foodcritic, rubocop and knife test are invoked to check Chef cookbook syntax
#
# test-cookbook.sh uses bundler to fetch the following gems:
# - foodcritic
# - rubocop
# - rails-erb-check
# - jsonlint
# - yaml-lint

# Exit at first failure
set -e

# Fixes issue https://github.com/berkshelf/berkshelf-api/issues/112
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

echo "[test-cookbook.sh] Start"

# Generate Gemfile, containing all gems used below for linting and testing
echo "[test-cookbook.sh] Creating GemfileTemp for test run"

cat <<EOF > GemfileTemp
source 'https://rubygems.org'

gem 'foodcritic'
gem 'rubocop'
gem 'rails-erb-check'
gem 'jsonlint'
gem 'yaml-lint'
EOF

curl -L https://raw.githubusercontent.com/Alfresco/chef-commons/master/scripts/get-gems.sh --no-sessionid | bash -s -- ./GemfileTemp

# Running All checks per types
echo "[test-cookbook.sh] Running all checks/tests per filetype"
find . -name "*.erb" -exec rails-erb-check {} \;
find . -name "*.json" -exec jsonlint {} \;
find . -name "*.rb" -exec ruby -c {} \;
find . -name "*.yml" -not -path "./.kitchen.yml" -exec yaml-lint {} \;

# Run knife, foodcritic and rubocop, if this is a Chef recipe
if [ -d './recipes' ]
then
  echo "[test-cookbook.sh] Running Knife test"
  knife cookbook test cookbook -o ./ -a
  echo "[test-cookbook.sh] Running Foodcritic"
  foodcritic -f any .
  # Next one should use warning as fail-level, printing only the progress review
  echo "[test-cookbook.sh] Running Rubocop"
  rubocop --fail-level warn | sed -n 2p
fi
