ruby_block 'start-instance' do
  block do
    InstanceSemaphore.start(node)
  end
  action :run
end
