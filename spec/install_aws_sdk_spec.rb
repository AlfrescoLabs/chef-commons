require 'chefspec'
require 'rspec'
require 'chefspec/berkshelf'

RSpec.describe 'commons::install_aws_sdk' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(
      platform: 'centos',
      version: '7.2.1511',
      file_cache_path: '/var/chef/cache'
    ) do |node|
    end.converge(described_recipe)
  end

  it 'installs aws-sdk gem' do
    expect(chef_run).to install_chef_gem('aws-sdk')
  end
end
