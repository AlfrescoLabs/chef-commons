if node['commons']['logstash'] and node['commons']['logstash']['ec2'] and node['commons']['logstash']['ec2']['run_discovery']

  logstash_servers_path = "/tmp/logstash_servers.tmp"
  file logstash_servers_path do
    action :create
  end

  ruby_block 'run-ec2-discovery' do
    block do
      # Run EC2 discovery
      ec2_discovery_output = Ec2Discovery.discover(node['commons']['ec2_discovery'])

      ec2_discovery_output.each do |server|
        logstash_servers << server['ip']
      end
      File.open(logstash_servers_path, 'w') { |file| file.write(JSON.parse(logstash_servers).to_s) }
    end
    action :run
  end

  replace_or_add "setup_logstash_servers" do
    path "/etc/logstash-forwarder.conf"
    pattern "\"servers\": "
    line "\"servers\": #{File.open(logstash_servers_path, "rb").read}"
    notifies :restart, 'service[logstash-forwarder]', :delayed
    only_if { File.exist?('/etc/logstash-forwarder.conf')}
  end

  service 'logstash-forwarder' do
    action :nothing
  end
end
