
class Chef
  module Ec2Discovery


    class << self

      include Chef::Mixin::ShellOut

      def discover(config)
        aws_bin = config['aws_command']
        wget_bin = config['wget_command']
        ec2_peers_file_path = config['peers_file_path']
        ec2_current_file_path = config['current_file_path']
        query_tags = config['query_tags']
        skip_ec2_commands = config['skip_ec2_commands']
        puts " [EC2 Discovery] Running...\n"

        query_tag_filter = ""
        if query_tags
          query_tags.each do |tagName,tagValue|
            query_tag_filter += "--filters Name=tag:#{tagName},Values=#{tagValue} "
          end
        end

        # Create ec2 files, current and peers
        run_cmd("#{aws_bin} ec2 describe-instances #{query_tag_filter} > #{ec2_peers_file_path}") unless skip_ec2_commands
        ec2_peers_file = JSON.parse(File.read(ec2_peers_file_path))
        puts " [EC2 Discovery] Loaded ec2_peers JSON:\n#{ec2_peers_file}'\n"

        run_cmd("#{wget_bin} -q -O - http://169.254.169.254/latest/meta-data > #{ec2_current_file_path}") unless skip_ec2_commands
        ec2_current_file = JSON.parse(File.read(ec2_current_file_path))
        puts " [EC2 Discovery] Loaded ec2_current JSON:\n#{ec2_current_file}'\n"

        puts " [EC2 Discovery] Parsing EC2 instances using config:\n#{config}'\n"
        output = {}

        if ec2_peers_file['Reservations'] and ec2_peers_file['Reservations'].length > 0
          puts " [EC2 Discovery] Found EC2 #{ec2_peers_file['Reservations'].size()} instances\n"
          ec2_peers_file['Reservations'].each do |reservation|
            reservation['Instances'].each do |awsnode|
              config['output']['elements'].each do |elementName,elementValue|
                output[elementName] = getSubAttribute(awsnode,elementValue)
                puts " [EC2 Discovery] Writing output element #{elementName}=#{output[elementName]}\n"
              end
              config['output']['tags'].each do |tagName,tagValue|
                value = ""
                awsnode['Tags'].each do |tag|
                  if tag['Key'] == tagValue
                    value = tag['Value']
                  end
                end
                output[tagName] = value
                puts " [EC2 Discovery] Writing output tag #{tagName}=#{value}\n"
              end

              # TODO - ...
            end
          end
        end
        puts " [EC2 Discovery] Returning output #{output}\n"
        return output


        #     private_ip = awsnode['PrivateIpAddress']
        #     availability_zone = awsnode['Placement']['AvailabilityZone']
        #     status = awsnode['State']['Name']
        #     id = awsnode['InstanceId']
        #     Chef::Log.info("Parsing EC2 instance '#{id}', status '#{status}', avaliability zone '#{availability_zone}', private IP '#{private_ip}'")
        #
        #     role = ""
        #     instanceName = ""
        #
        #     if status == "running"
        #
        #       # 1. Collect Name and role_tag values from AWS tags
        #       awsnode['Tags'].each do |tag|
        #         if tag['Key'] == "Name"
        #           instanceName = tag['Value']
        #         elsif tag['Key'] == role_tag_name
        #           role = tag['Value']
        #         end
        #       end
        #
        #       # Define node and haproxy backend configuration
        #       Chef::Log.info("EC2 instance '#{id}' has role '#{role}'")
        #       haproxy_backends[role] = {} unless haproxy_backends[role]
        #
        #       haproxy_backends[role]['zones'] = {} unless haproxy_backends[role]['zones']
        #
        #       unless haproxy_backends[role]['zones'][availability_zone]
        #         haproxy_backends[role]['zones'][availability_zone] = {}
        #         haproxy_backends[role]['zones'][availability_zone]['nodes'] = {}
        #       end
        #
        #       haproxy_backends[role]['zones'][availability_zone]['current'] = true if current_availability_zone == availability_zone
        #
        #       unless current_private_ip == private_ip
        #         haproxy_backends[role]['zones'][availability_zone]['nodes'][id] = {}
        #         haproxy_backends[role]['zones'][availability_zone]['nodes'][id]['ip'] = private_ip
        #         Chef::Log.info("haproxy-ec2-discovery: Discovered node with ip '#{private_ip}', role '#{role}' and availability_zone '#{availability_zone}'")
        #
        #         if role == "share" || role == "allinone"
        #           backend_options = "check cookie #{instanceName.split('-')[1]} inter 5000"
        #         end
        #
        #         haproxy_backends[role]['zones'][availability_zone]['nodes'][id]['options'] = backend_options
        #       else
        #         Chef::Log.info("Skipping instance #{private_ip} as it's the current instance")
        #         if role == "share" || role == "allinone"
        #           haproxy_backends[role]['local_options'] = "check cookie #{instanceName.split('-')[1]} inter 5000"
        #         end
        #       end
        #
        #       if role == 'allinone'
        #         allinone_local_share_options = haproxy_backends[role]['local_options']
        #         allinone_local_options = "check inter 5000"
        #         allinone_backup_options = "check inter 5000 backup"
        #       end
        #     end
        #   end
        # end
        # end
        #
        # if haproxy_backends['allinone']
        # haproxy_backends['alfresco']['zones'] = haproxy_backends['allinone']['zones']
        # haproxy_backends['share']['zones'] = haproxy_backends['allinone']['zones']
        # haproxy_backends['solr']['zones'] = haproxy_backends['allinone']['zones']
        # end
        #
        # # AOS backend is hosted by alfresco, so it inherits same haproxy configurations
        # if haproxy_backends['alfresco'] and haproxy_backends['aos_vti'] and haproxy_backends['aos_root']
        # haproxy_backends['aos_vti']['zones'] = haproxy_backends['alfresco']['zones']
        # haproxy_backends['aos_root']['zones'] = haproxy_backends['alfresco']['zones']
        # end
        # Chef::Log.info("Haproxy backends: #{haproxy_backends}")
      end

      private

      def run_cmd(command)
        cmd = shell_out!(command, {:returns => [0,2]})
        cmd.error!
      end

      def getSubAttributeArray(node,path_array)
        # puts "[DEBUG] getSubAttributeArray(#{node},#{path_array}) \n"
        unless node
          Application.fatal!("Commons::Helper.getSubAttribute failed! node is null while trying to resolve attribute #{path_array}")
        end

        return node if node.kind_of?(String)

        if path_array and path_array.size() > 0
          return getSubAttributeArray(node[path_array[0]], path_array[1..-1])
        end
      end

      def getSubAttribute(node,path)
        # puts "[DEBUG] getSubAttribute(#{node},#{path}) \n"
        ret = path ? getSubAttributeArray(node,path.split('/')) : nil
      end
    end
  end
end
