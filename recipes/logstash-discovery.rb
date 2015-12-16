commons_logstash_discovery 'discover' do
  config node['commons']['ec2_discovery']
  action :run
  only_if { node['commons']['logstash'] and node['commons']['logstash']['ec2'] and node['commons']['logstash']['ec2']['run_discovery'] }
end
