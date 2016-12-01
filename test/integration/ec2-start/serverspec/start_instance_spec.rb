require 'spec_helper'

# it should have been created
describe command('aws s3 ls s3://ec2-start-kitchen-bucketname-todelete') do
  its(:stdout) { should be_empty }
  its(:stderr) { should be_empty }
end
