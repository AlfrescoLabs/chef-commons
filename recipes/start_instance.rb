Chef::Resource::RubyBlock.send(:include, InstanceSemaphore)

ruby_block 'start-instance' do
  block do
    if node['semaphore']['parallel']
      start_parallel(node)
    else
      start(node)
    end
  end
  action :run
end
