Chef::Resource::RubyBlock.send(:include, InstanceSemaphore)

ruby_block 'start-instance' do
  block do
    start(node)
  end
  action :run
end
