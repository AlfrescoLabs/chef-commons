default['commons']['ec2_discovery']['aws_command'] = node['commons']['awscli']['aws_command']
default['commons']['ec2_discovery']['wget_command'] = 'wget'

# Used for local testing
default['commons']['ec2_discovery']['skip_ec2_commands'] = false

# Example of elements you want to output for each instance discovered
#
# default['commons']['ec2_discovery']['output']['elements']['state'] = 'State/Name'
# default['commons']['ec2_discovery']['output']['elements']['id'] = 'InstanceId'
# default['commons']['ec2_discovery']['output']['elements']['ip'] = "PrivateIpAddress"
# default['commons']['ec2_discovery']['output']['elements']['az'] = 'Placement/AvailabilityZone'
# default['commons']['ec2_discovery']['output']['tags']['roles'] = 'roles'
# default['commons']['ec2_discovery']['output']['tags']['instance_name'] = 'Name'
# default['commons']['ec2_discovery']['output']['tags']['jvm_route'] = 'jvm_route'

# Example of elements (defined above) used for grouping instances
#
# default['commons']['ec2_discovery']['group_by'] = ['roles','az','id']

# Example to filter in only instances with state=running
#
# default['commons']['ec2_discovery']['filter_in']['state'] = "running"

# Example to filter out the current instance from the list of results
#
# default['commons']['ec2_discovery']['filter_out']['current_ip'] = true

# Example to filter in the instances to analyze from EC2
#
# default['commons']['ec2_discovery']['query_tags']['status'] = "complete"
# default['commons']['ec2_discovery']['query_tags']['stack_name'] = "mystack"

# The example above will build the following attributes (for each instance):
#
# node['roles']['myrole']['az']['myaz']['id']['i-123456']['id'] = "i-123456"
# node['roles']['myrole']['az']['myaz']['id']['i-123456']['state'] = "running"
# node['roles']['myrole']['az']['myaz']['id']['i-123456']['ip'] = "172.2.2.2"
# node['roles']['myrole']['az']['myaz']['id']['i-123456']['az'] = "myaz"
# node['roles']['myrole']['az']['myaz']['id']['i-123456']['roles'] = "myrole"
# node['roles']['myrole']['az']['myaz']['id']['i-123456']['instance_name'] = "i-123456"
# node['roles']['myrole']['az']['myaz']['id']['i-123456']['jvm_route'] = "myserver1"
