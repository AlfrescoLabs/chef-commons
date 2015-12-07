require 'spec_helper'

describe file('/etc/ssl/certs/mycertname.pem') do
  it { should be_file }
end
describe file('/etc/ssl/certs/mycertname.crt') do
  it { should be_file }
end
describe file('/etc/ssl/certs/mycertname.key') do
  it { should be_file }
end

describe file('/etc/ssl/certs/mycertname.pem') do
  its(:content) { should match /a PEM file/ }
end
