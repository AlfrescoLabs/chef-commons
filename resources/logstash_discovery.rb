property :enable_discovery, String

load_current_value do
  if ::File.exist?('/etc/logstash-forwarder.conf')
    enable_discovery "true"
  end
end

action :run do
  logstash_servers = []

  # Run EC2 discovery
  ec2_discovery_output = Ec2Discovery.discover(node['commons']['ec2_discovery'])

  ec2_discovery_output.each do |serverItem,server|
    Chef::Log.info("Adding logstash server: #{server}")
    logstash_servers << server['ip']
  end
  Chef::Log.info("Logstash servers found: #{logstash_servers}")

  replace_or_add "setup_logstash_servers" do
    path "/etc/logstash-forwarder.conf"
    pattern "\"servers\": "
    line "\"servers\": #{logstash_servers.to_json}"
    notifies :restart, 'service[logstash-forwarder]', :delayed
    only_if { :enable_discovery == "true" }
  end

  service 'logstash-forwarder' do
    action :nothing
  end
end
