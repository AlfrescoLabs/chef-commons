ruby_block 'stop-instance' do
  block do
    InstanceSemaphore.stop(node)
  end
  action :run
end
