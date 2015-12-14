# This recipe aims to help discovery process in EC2;
# it runs AWS commandline to tag the current EC2 instance
# with a list of given key=value pairs (node['commons']['ec2']['box_tags'])
#
box_tags = node['commons']['ec2_tags']
aws_bin = node['commons']['awscli']['aws_command']

#TODO - use aws cookbook
# aws_resource_tag node['commons']['ec2']['instance_id'] do
#   aws_access_key aws['aws_access_key_id']
#   aws_secret_access_key aws['aws_secret_access_key']
#   tags({"Name" => "www.example.com app server",
#         "Environment" => node.chef_environment})
#   action :update
# end

instance_id_command = "$(wget -q -O - http://169.254.169.254/latest/meta-data/instance-id)"

if box_tags
  box_tags_str = "--tags "
  box_tags.each do |tagName,tagValue|
        box_tags_str += "Key=#{tagName},Value=\\\"#{tagValue}\\\" "
  end
  execute "set-ec2-tags" do
    command "#{aws_bin} ec2 create-tags --resources #{instance_id_command} #{box_tags_str}"
  end
end
