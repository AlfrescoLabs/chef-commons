require 'chefspec'
require 'rspec'
require 'chefspec/berkshelf'

RSpec.describe 'commons::stop_instance' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(
      platform: 'centos',
      version: '7.2.1511',
      file_cache_path: '/var/chef/cache'
    ) do |node|
    end.converge(described_recipe)
  end

  it 'runs stop-instance' do
    expect(chef_run).to run_ruby_block('stop-instance')
  end
end
