# The path to awscli executable - https://aws.amazon.com/cli
default['commons']['ec2']['aws_bin'] = "aws"

# Peers are retrieved using aws commandline tool and stored in a local file
default['commons']['ec2']['peers_file_path'] = "/etc/chef/ec2-peers.json"

# Default query returns the PrivateIpAddress, but can be changed
default['commons']['ec2']['attribute_to_fetch'] = 'PrivateIpAddress'

# Only discover running instances
default['commons']['ec2']['only_running_instances'] = true

# EC2 tags can be used to identify peers
# default['commons']['ec2']['query_tags']['status'] = "complete"
# default['commons']['ec2']['query_tags']['stack_name'] = "mystack"

# Peers are grouped based on the value of an EC2 Tag
# default['commons']['ec2']['group_by_tag'] = "tagNameExample"
