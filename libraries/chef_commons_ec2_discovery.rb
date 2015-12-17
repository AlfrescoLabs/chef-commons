
class Chef

  module Ec2Discovery
    class << self
      include Chef::Mixin::ShellOut

      def setDeepAttribute(node,path_array,value)
        if path_array.size() == 1
          node[path_array[0]] = value
        else
          node[path_array[0]] = {} unless node[path_array[0]]
          setDeepAttribute(node[path_array[0]],path_array[1..-1],value)
        end
      end

      def discover(config)
        # Cloning, loading and parsing configuration
        cfg = config.to_hash.clone
        aws_bin = cfg['aws_command']
        wget_bin = cfg['wget_command']
        query_tags = cfg['query_tags']
        skip_ec2_commands = cfg['skip_ec2_commands']
        group_by = cfg['group_by']
        filter_in = cfg['filter_in']
        filter_out = cfg['filter_out']
        query_tag_filter = getAwsQueryFilter(config['query_tags'])
        output = {}

        # If current instance params are provided, there's no need
        # to invoke aws command
        puts " [EC2 Discovery] Start!\n"
        if cfg['current']
          current_ip = cfg['current']['ip']
          current_az = cfg['current']['az']
          ec2_peers = File.read('/etc/chef/ec2-peers.json')
        else
          current_ip = getAwsMetadata(wget_bin, 'local-ipv4')
          current_az = getAwsMetadata(wget_bin, 'placement/availability-zone')
          puts "[EC2 Discovery] Running AWS Command: #{aws_bin} ec2 describe-instances #{query_tag_filter}\n"
          ec2_peers = run_cmd("#{aws_bin} ec2 describe-instances #{query_tag_filter}")
        end
        puts "[EC2 Discovery] Current ip: #{current_ip}\n"
        puts "[EC2 Discovery] Current az: #{current_az}\n"

        ec2_peers_hash = JSON.parse(ec2_peers)
        # puts " [EC2 Discovery] Loaded ec2_peers JSON #{ec2_peers_hash} and Config #{config}'\n"

        if ec2_peers_hash['Reservations'] and ec2_peers_hash['Reservations'].length > 0
          ec2_peers_hash['Reservations'].each do |reservation|
            reservation['Instances'].each_with_index do |awsnode,i|
              instance_details = {}

              # Collect element values
              if cfg['output']['elements']
                cfg['output']['elements'].each do |element_name,element_value|
                  instance_details[element_name] = getSubAttributeStr(awsnode,element_value)
                end
              end

              # Collect tag values
              if cfg['output']['tags']
                cfg['output']['tags'].each do |tag_name,tag_value|
                  instance_details[tag_name] = getTagValue(awsnode['Tags'], tag_value)
                end
              end

              # Filter in instances
              filtered_in = true
              if filter_in
                filter_in.each do |field_name,field_value|
                  filtered_in = false if instance_details[field_name] != field_value
                end
              end

              # Filter out instances
              filtered_out = false
              if filter_out
                filter_out.each do |field_name,field_value|
                  if field_name == 'current_ip'
                    field_name = 'ip'
                    field_value = current_ip
                  end
                  filtered_out = true if instance_details[field_name] == field_value
                end
              end

              # Add instance to the output list, if not filtered
              if filtered_in and !filtered_out
                if group_by
                  setFacetAttribute(output,group_by,instance_details)
                else
                  setDeepAttribute(output,[i.to_s],instance_details)
                end
                puts "[EC2 Discovery] Registered EC2 instance #{instance_details}\n"
              else
                puts "[EC2 Discovery] Filtered out EC2 instance #{instance_details}\n"
              end
            end
          end
        end
        puts "[EC2 Discovery] DEBUG: Returning output \n#{JSON.pretty_generate(output)}\n"
        return output
      end

      private

      def run_cmd(command)
        cmd = shell_out!(command)
        return cmd.stdout
      end

      def getAwsMetadata(wget_bin, item)
         return run_cmd("#{wget_bin} -q -O - http://169.254.169.254/latest/meta-data/#{item}")
      end

      def getAwsQueryFilter(query_tags)
        query_tag_filter = ""
        if query_tags
          query_tags.each do |tagName,tagValue|
            query_tag_filter += "--filters Name=tag:#{tagName},Values=#{tagValue} "
          end
        end
        return query_tag_filter
      end

      def getSubAttributeStr(node,path)
        return getSubAttribute(node,path.split('/'))
      end

      def getSubAttribute(node,path_array)
        # puts "[DEBUG] getSubAttribute(#{node},#{path_array}) \n"
        unless node
          Application.fatal!("Commons::Helper.getSubAttribute failed! node is null while trying to resolve attribute #{path_array}")
        end

        if path_array and path_array.size() == 0
          return node
        else
          return getSubAttribute(node[path_array[0]], path_array[1..-1])
        end
      end

      def stringToArray(string)
        return string.split(',') if string.include? ','
        return nil
      end

      def setFacetAttribute(node,path_array,value)
        # puts "[DEBUG] setFacetAttribute(#{node.to_json},#{path_array},#{value}) \n"
        unless node and path_array
          Application.fatal!("Commons::Helper.setFacetAttribute failed! node or path_array is null while trying to set value #{value} on attribute #{path_array}")
        end
        attribute_group_name = path_array[0]
        facet_value = value[path_array[0]]
        facet_value_array = stringToArray(facet_value)
        if path_array.size() == 1
          if facet_value_array
            facet_value_array.each do |facet_value_item|
              node[attribute_group_name] = {} unless node[attribute_group_name]
              node[attribute_group_name][facet_value_item] = value
            end
          else
            node[attribute_group_name] = {} unless node[attribute_group_name]
            node[attribute_group_name][facet_value] = value
          end
        else
          if facet_value_array
            facet_value_array.each do |facet_value_item|
              node[attribute_group_name] = {} unless node[attribute_group_name]
              node[attribute_group_name][facet_value_item] = {} unless node[attribute_group_name][facet_value_item]
              setFacetAttribute(node[attribute_group_name][facet_value_item], path_array[1..-1],value)
            end
          else
            node[attribute_group_name] = {} unless node[attribute_group_name]
            node[attribute_group_name][facet_value] = {} unless node[attribute_group_name][facet_value]
            setFacetAttribute(node[attribute_group_name][facet_value], path_array[1..-1],value)
          end
        end
      end

      def getTagValue(input_tags_array, tag_value_match)
        input_tags_array.each do |tag|
          if tag['Key'] == tag_value_match
            return tag['Value']
          end
        end
      end
    end
  end
end
