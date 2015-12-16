property :enable_discovery, kind_of: [TrueClass, FalseClass], default: false
property :config, required: true
property :ouput, default: []

load_current_value do
  if ::File.exist?('/etc/logstash-forwarder.conf')
    # Run EC2 discovery
    ec2_discovery = Ec2Discovery.discover(:config)
    logstash_servers = []
    ec2_discovery.each do |serverItem,server|
      Chef::Log.info("Adding logstash server: #{server}")
      logstash_servers << server['ip']
    end
    Chef::Log.info("Logstash servers found: #{logstash_servers}")

    output logstash_servers
    enable_discovery true
  end
end

action :run do
  load_current_value :output do
    replace_or_add "setup_logstash_servers" do
      path "/etc/logstash-forwarder.conf"
      pattern "\"servers\": "
      line "\"servers\": #{output.to_json}"
      notifies :restart, 'service[logstash-forwarder]', :delayed
      only_if { :enable_discovery }
    end

    service 'logstash-forwarder' do
      action :nothing
      only_if "service logstash-forwarder status"
    end
  end
end
