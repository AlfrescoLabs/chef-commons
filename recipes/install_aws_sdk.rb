chef_gem 'aws-sdk' do
  version node['aws']['aws_sdk_version']
  compile_time true if Chef::Resource::ChefGem.instance_methods(false).include?(:compile_time)
  action :install
end

require 'aws-sdk'
