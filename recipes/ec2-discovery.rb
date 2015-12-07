# commons::ec2-discovery implements an alternative to ohai-ec2
#
peers_file_path = node['commons']['ec2-discovery']['peers_file_path']
current_file_path = node['commons']['ec2-discovery']['current_file_path']

directory File.dirname(peers_file_path) do
  recursive true
  action :create
end

directory File.dirname(current_file_path) do
  recursive true
  action :create
end

ruby_block 'ec2-discovery' do
  block do
    # Invoke Commons::Helper.discover_ec2
    Ec2Discovery.discover(node['commons']['ec2-discovery'])
  end
  action :run
end
