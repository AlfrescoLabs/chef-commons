ruby_block 'wait-instance' do
  block do
    InstanceSemaphore.wait_while_service_up(node)
  end
  action :run
end
