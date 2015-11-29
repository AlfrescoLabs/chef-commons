# Add scripts to /usr/local/bin
remote_directory "/usr/local/bin" do
  source "chefzero_scripts"
  purge false
  files_mode 00755
end
