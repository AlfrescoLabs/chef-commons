require 'spec_helper'

describe command('find /root/.gem/specs/api.rubygems.org%443/quick -type f -name aws-sdk*.gemspec -printf "%f\n"') do
  its(:stdout) { should contain /aws-sdk-/ }
  its(:stdout) { should contain /aws-sdk-core-/ }
  its(:stdout) { should contain /aws-sdk-resources-/ }
end
