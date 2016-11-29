remote_directory '/etc/chef' do
  source 'ec2_mock_files'
  purge false
  files_mode '0600'
end

file '/etc/logstash-forwarder.conf' do
  content "\"servers\": ['1.2.3.4', '2.3.4.5']"
end
