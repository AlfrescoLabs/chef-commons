require 'spec_helper'

#it should have been deleted
describe command('aws s3 ls s3://ec2-start-kitchen-bucketname-todelete') do
  its(:stderr) { should contain /The specified bucket does not exist/ }
end
