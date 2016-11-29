# TODO: this is not needed... should be a test recipe
#
# commons::ec2-discovery implements an alternative to ohai-ec2
#
ruby_block 'ec2-discovery' do
  block do
    # Invoke Commons::Helper.discover_ec2
    Ec2Discovery.discover(node['commons']['ec2_discovery'])
  end
  action :run
end
