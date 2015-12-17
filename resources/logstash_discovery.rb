property :enable_discovery, kind_of: [TrueClass, FalseClass], default: false
property :lumberjack_port

load_current_value do
  if ::File.exist?('/etc/logstash-forwarder.conf') and node['commons']['logstash'] and node['commons']['logstash']['ec2'] and node['commons']['logstash']['ec2']['run_discovery']
    enable_discovery true
  end
end

action :run do
  logstash_servers = []

  # Run EC2 discovery
  ec2_discovery_output = Ec2Discovery.discover(node['commons']['ec2_discovery'])

  ec2_discovery_output.each do |serverItem,server|
    Chef::Log.info("Adding logstash server: #{server}")

    # TODO - currently relying on ip/name/domain elements to be set
    replace_or_add "register_logstash_server_#{server['name']}.#{server['domain']}_on_etc_hosts" do
      path "/etc/hosts"
      pattern "#{server['ip']} "
      line "#{server['ip']} #{server['name']}.#{server['domain']}"
    end

    logstash_servers << "#{server['name']}.#{server['domain']}:#{lumberjack_port}"
  end
  Chef::Log.info("Logstash servers found: #{logstash_servers}")

  replace_or_add "setup_logstash_servers" do
    path "/etc/logstash-forwarder.conf"
    pattern "\"servers\": "
    line "\"servers\": #{logstash_servers.to_json},"
    notifies :restart, 'service[logstash-forwarder]', :delayed
    only_if { :enable_discovery }
  end

  service 'logstash-forwarder' do
    action :nothing
    only_if "service logstash-forwarder status"
  end
end
