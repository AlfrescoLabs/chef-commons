describe file('/etc/chef/test1.json') do
  it { should be_file }
end

describe file('/etc/cron.d/test1.cron') do
  it { should be_file }
  its(:content) { should match %r{\/etc\/chef\/test1.json} }
end
