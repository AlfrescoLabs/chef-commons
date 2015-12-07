remote_directory "/etc/chef" do
  source "ec2_mock_files"
  purge false
  files_mode '0600'
end
