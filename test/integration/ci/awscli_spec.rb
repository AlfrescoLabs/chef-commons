describe file('/usr/local/bin/berkshelf-checkout.sh') do
  it { should be_file }
end

describe file('/usr/local/bin/run-chef-client.sh') do
  it { should be_file }
end
