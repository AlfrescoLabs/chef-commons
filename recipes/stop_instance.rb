Chef::Resource::RubyBlock.send(:include, InstanceSemaphore)

ruby_block 'stop-instance' do
  block do
    if node['semaphore']['parallel']
      stop_parallel(node)
    else
      stop(node)
    end
  end
  action :run
end
