require 'serverspec'

set :backend, :exec

begin
  require 'rspec_junit_formatter'
rescue LoadError
  require 'rubygems/dependency_installer'
  Gem::DependencyInstaller.new.install('rspec_junit_formatter')
  require 'rspec_junit_formatter'
end

RSpec.configure do |c|
  c.path = '/sbin:/usr/sbin:/usr/bin:/bin'
  c.add_formatter 'RspecJunitFormatter', '/vagrant/kitchen-integration-ec2-start.xml'
end
