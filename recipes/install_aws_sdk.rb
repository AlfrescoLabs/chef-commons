chef_gem 'aws-sdk' do
  version node['aws']['aws_sdk_version']
  compile_time true if Chef::Resource::ChefGem.instance_methods(false).include?(:compile_time)
  action :install
  retries node['aws']['aws_sdk_retries']
  retry_delay node['aws']['aws_sdk_retries_delay']
end
