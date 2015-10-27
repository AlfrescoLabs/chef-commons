# This recipe aims to help discovery process in EC2;
# it runs AWS commandline to discover other EC2 instances
# depending on their tags (node['genius']['ec2']['query_tags']);
# results can be grouped by the value of a given tag
# (node['genius']['ec2']['group_by_tag']); IPs returned can be either
# Private or Public (node['genius']['ec2']['query'])
#
aws_bin = node['genius']['ec2']['aws_bin']
peers_file_path = node['genius']['ec2']['peers_file_path']
query_tags = node['genius']['ec2']['query_tags']
group_by_tag = node['genius']['ec2']['group_by_tag']
only_running_instances = node['genius']['ec2']['only_running_instances']
attribute_to_fetch = node['genius']['ec2']['attribute_to_fetch']

# Query AWS instances and set node attributes for haproxy service discovery configuration
if query_tags
  query_tag_filter = ""
  query_tags.each do |tagName,tagValue|
    query_tag_filter += "--filters Name=tag:#{tagName},Values=#{tagValue} "
  end

  execute "create-ec2-peers-json" do
    command "#{aws_bin} ec2 describe-instances #{query_tag_filter} > #{peers_file_path}"
    # re-create it every time
    # creates peers_file_path
  end

  # TODO - refactor with:
  # aws ec2 describe-instances --query "Reservations[*].Instances[*].PublicIpAddress" --output text --filters Name=tag:Status,Values=complete
  # aws ec2 describe-instances --query "#{query}" --output text #{query_tag_filter}

  ruby_block "handling-#{peers_file_path}" do
    block do
      file = File.read(peers_file_path)
      peers_hash = JSON.parse(file)
      if peers_hash['Reservations'] and peers_hash['Reservations'].length > 0
        peers_hash['Reservations'][0]['Instances'].each do |awsnode|
          instance_ip = awsnode[attribute_to_fetch]
          status = awsnode['State']['Name']
          id = awsnode['InstanceId']
          if !only_running_instances or status == "running"
            awsnode['Tags'].each do |tag|
              if group_by_tag
                if tag['Key'] == group_by_tag
                  role = tag['Value']
                  node.default['ec2']['peers'][role][id] = instance_ip
                end
              else
                  node.default['ec2']['peers'][id] = instance_ip
              end
            end
          end
        end
      end
    end
    action :run
  end
end
