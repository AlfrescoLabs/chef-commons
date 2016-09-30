Chef::Resource::RubyBlock.send(:include, InstanceSemaphore)

ruby_block 'wait-instance' do
  block do
    wait_while_service_up(node)
  end
  action :run
end
