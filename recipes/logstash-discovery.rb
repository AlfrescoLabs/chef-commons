commons_logstash_discovery 'discover' do
  action :run
  only_if { node['commons']['logstash'] and node['commons']['logstash']['ec2'] and node['commons']['logstash']['ec2']['run_discovery'] }
end
