Chef::Resource::RubyBlock.send(:include, InstanceSemaphore)

ruby_block 'wait-instance' do
  block do
    if node['semaphore']['parallel']
      wait_while_service_up_parallel(node)
    else
      wait_while_service_up(node)
    end
  end
  action :run
  ignore_failure true
end
