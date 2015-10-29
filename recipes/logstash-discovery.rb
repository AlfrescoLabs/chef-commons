discovery_chef_json = node['genius']['logstash']['discovery-chef-json']
ec2_role_name = node['genius']['logstash']['ec2_role_name']
run_discovery = node['genius']['logstash']['run_discovery']

directory File.dirname(discovery_chef_json) do
  action :create
end

template discovery_chef_json do
  source 'logstash/logstash-discovery.json.erb'
end

template '/etc/cron.d/discover-logstash.cron' do
  source 'logstash/discover-logstash.cron.erb'
end

service 'logstash-forwarder' do
  action :nothing
end

if run_discovery
  if node['genius']['ec2']['peers'][ec2_role_name]
    logstash_servers = []
    node['genius']['ec2']['peers'][ec2_role_name].each do |instanceName,instanceIp|
      logstash_servers << instanceIp
    end
  end

  replace_or_add "logstash-forwarder-conf-servers-setup" do
    path "/etc/logstash-forwarder.conf"
    pattern "logstash_servers: "
    line "logstash_servers: #{logstash_servers}"
    notifies :restart, 'service[logstash-forwarder]', :delayed
    not_if { File.exist?('/etc/logstash-forwarder.conf')}
  end
end
