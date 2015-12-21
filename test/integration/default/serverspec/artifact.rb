require 'serverspec'

set :backend, :exec

describe file('/home/vagrant/default_suite/junit1.jar') do
  it { should be_file  }
end
