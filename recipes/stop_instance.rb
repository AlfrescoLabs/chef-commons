Chef::Resource::RubyBlock.send(:include, InstanceSemaphore)

ruby_block 'stop-instance' do
  block do
    stop(node)
  end
  action :run
end
