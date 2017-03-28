node = json('/tmp/kitchen_chef_node.json').params['default']

# Based on default values
directory node['certs']['ssl_folder'] do
  it { should exist }
end

# By default we don't create self-signed ssl certs, we normally download them using databags
%w(key crt chain nginxcrt dhparam).each do |ssl_component|
  describe file("#{node['certs']['ssl_folder']}/#{node['certs']['filename']}.#{ssl_component}") do
    it { should_not exist }
  end
end
