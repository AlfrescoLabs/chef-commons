default['commons']['ec2-discovery']['aws_command'] = 'aws'
default['commons']['ec2-discovery']['wget_command'] = 'wget'

# Used for local testing
default['commons']['ec2-discovery']['skip_ec2_commands'] = false

default['commons']['ec2-discovery']['output']['elements']['state'] = 'State/Name'
default['commons']['ec2-discovery']['output']['elements']['id'] = 'InstanceId'
default['commons']['ec2-discovery']['output']['elements']['ip'] = "PrivateIpAddress"
default['commons']['ec2-discovery']['output']['elements']['az'] = 'Placement/AvailabilityZone'
default['commons']['ec2-discovery']['output']['tags']['roles'] = 'roles'
default['commons']['ec2-discovery']['output']['tags']['instance_name'] = 'Name'

default['commons']['ec2-discovery']['group_by'] = ['roles','az','id']

default['commons']['ec2-discovery']['filter_in']['state'] = "running"

default['commons']['ec2-discovery']['filter_out']['current_ip'] = true

# default['commons']['ec2-discovery']['query_tags']['status'] = "complete"
# default['commons']['ec2-discovery']['query_tags']['stack_name'] = "mystack"
