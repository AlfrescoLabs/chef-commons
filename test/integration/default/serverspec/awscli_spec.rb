require 'spec_helper'

describe command('aws') do
  its(:exit_status) { should eq 2 }
end

describe file('/root/.aws/credentials') do
  it { should be_file }
end

describe file('/root/.aws/credentials') do
  its(:content) { should match /aws_access_key_id/ }
  its(:content) { should match /aws_secret_access_key/ }
end
