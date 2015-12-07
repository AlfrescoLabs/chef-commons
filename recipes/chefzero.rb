# Add the following scripts to /usr/local/bin:
# berkshelf-checkout/sh - downloads Berkshelf tar.gz artifacts from a Maven repo
# run-chef-client.sh - runs chef in local mode
# 
remote_directory "/usr/local/bin" do
  source "chefzero_scripts"
  purge false
  files_mode '0600'
end
