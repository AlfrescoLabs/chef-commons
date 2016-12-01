class Chef
  module Ec2Discovery
    class << self
      include Chef::Mixin::ShellOut

      def set_deep_attribute(node, path_array, value)
        if path_array.size == 1
          node[path_array[0]] = value
        else
          node[path_array[0]] = {} unless node[path_array[0]]
          set_deep_attribute(node[path_array[0]], path_array[1..-1], value)
        end
      end

      def az_current
        get_aws_metadata('wget', 'placement/availability-zone')
      end

      def ip_current
        get_aws_metadata('wget', 'local-ipv4')
      end

      def discover(config)
        # Cloning, loading and parsing configuration
        cfg = config.to_hash.clone
        aws_bin = cfg['aws_command']
        # wget_bin = cfg['wget_command'] not used, may be useful in future
        # query_tags = cfg['query_tags'] not used, may be useful in future
        # query_filters = cfg['query_filters'] not used, may be useful in future
        # skip_ec2_commands = cfg['skip_ec2_commands'] not used, may be useful in future
        group_by = cfg['group_by']
        filter_in = cfg['filter_in']
        filter_out = cfg['filter_out']
        query_tag_filter = get_aws_query_filter(config['query_tags'], 'tag')
        query_filter = get_aws_query_filter(config['query_filters'], nil)
        filters = (query_tag_filter.to_s.strip.empty? || query_filter.to_s.strip.empty?) ? '' : "--filters #{query_tag_filter}#{query_filter}"

        output = {}

        # If current instance params are provided, there's no need
        # to invoke aws command
        puts '[EC2 Discovery] Start!\n'
        if cfg['current']
          current_ip = cfg['current']['ip']
          current_az = cfg['current']['az']
          ec2_peers = File.read('/etc/chef/ec2-peers.json')
        else
          current_ip = ip_current
          current_az = az_current
          puts "[EC2 Discovery] Running AWS Command: #{aws_bin} ec2 describe-instances #{filters} --region #{current_az[0...-1]}\n"
          ec2_peers = run_cmd("#{aws_bin} ec2 describe-instances #{filters} --region #{current_az[0...-1]}")
        end
        puts "[EC2 Discovery] Current ip: #{current_ip}\n"
        puts "[EC2 Discovery] Current az: #{current_az}\n"

        ec2_peers_hash = JSON.parse(ec2_peers)
        # puts " [EC2 Discovery] Loaded ec2_peers JSON #{ec2_peers_hash} and Config #{config}'\n"

        if ec2_peers_hash['Reservations'] && !ec2_peers_hash['Reservations'].empty?
          ec2_peers_hash['Reservations'].each do |reservation|
            reservation['Instances'].each_with_index do |awsnode, i|
              instance_details = {}

              # Collect element values
              if cfg['output']['elements'] && awsnode
                cfg['output']['elements'].each do |element_name, element_value|
                  instance_details[element_name] = get_sub_attribute_str(awsnode, element_value)
                end
              end

              # Collect element static values
              if cfg['output']['static']
                cfg['output']['static'].each do |element_name, element_value|
                  instance_details[element_name] = element_value
                end
              end

              # Collect tag values
              if cfg['output']['tags']
                cfg['output']['tags'].each do |tag_name, tag_value|
                  instance_details[tag_name] = get_tag_value(awsnode['Tags'], tag_value)
                end
              end

              # Filter in instances
              filtered_in = true
              if filter_in
                filter_in.each do |field_name, field_value|
                  filtered_in = false if instance_details[field_name] != field_value
                end
              end

              # Filter out instances
              filtered_out = false
              if filter_out
                filter_out.each do |field_name, field_value|
                  if field_name == 'current_ip'
                    field_name = 'ip'
                    field_value = current_ip
                  end
                  filtered_out = true if instance_details[field_name] == field_value
                end
              end

              # Add instance to the output list, if not filtered
              if filtered_in && !filtered_out
                if group_by
                  set_facet_attribute(output, group_by, instance_details)
                else
                  set_deep_attribute(output, [i.to_s], instance_details)
                end
                puts "[EC2 Discovery] Registered EC2 instance #{instance_details}\n"
              else
                puts "[EC2 Discovery] Filtered out EC2 instance #{instance_details}\n"
              end
            end
          end
        end
        puts "[EC2 Discovery] DEBUG: Returning output \n#{JSON.pretty_generate(output)}\n"
        output
      end

      private

      def run_cmd(command)
        cmd = shell_out!(command, user: 'root')
        cmd.stdout
      end

      def get_aws_metadata(wget_bin, item)
        run_cmd("#{wget_bin} -q -O - http://169.254.169.254/latest/meta-data/#{item}")
      end

      def get_aws_query_filter(query_tags, type)
        attr_type = type.to_s.strip.empty? ? '' : "#{type}:"
        query_tag_filter = ''
        if query_tags
          query_tags.each do |tag_name, tag_value|
            query_tag_filter += "\"Name=#{attr_type}#{tag_name},Values=#{tag_value}\" "
          end
        end
        query_tag_filter
      end

      def get_sub_attribute_str(node, path)
        get_sub_attribute(node, path.split('/'))
      end

      def get_sub_attribute(node, path_array)
        # puts "[DEBUG] get_sub_attribute(#{node},#{path_array}) \n"
        unless node
          Application.fatal!("Commons::Helper.get_sub_attribute failed! node is null while trying to resolve attribute #{path_array}")
        end

        return node if path_array && path_array.empty?
        get_sub_attribute(node[path_array[0]], path_array[1..-1])
      end

      def string_to_array(string)
        return string.split(',') if string.include? ','
        nil
      end

      def set_facet_attribute(node, path_array, value)
        # puts "[DEBUG] set_facet_attribute(#{node.to_json},#{path_array},#{value}) \n"
        unless node && path_array
          Application.fatal!("Commons::Helper.set_facet_attribute failed! node or path_array is null while trying to set value #{value} on attribute #{path_array}")
        end
        attribute_group_name = path_array[0]
        facet_value = value[path_array[0]]
        facet_value_array = string_to_array(facet_value)
        if path_array.size == 1
          if facet_value_array
            facet_value_array.each do |facet_value_item|
              node[attribute_group_name] = {} unless node[attribute_group_name]
              node[attribute_group_name][facet_value_item] = value
            end
          else
            node[attribute_group_name] = {} unless node[attribute_group_name]
            node[attribute_group_name][facet_value] = value
          end
        elsif facet_value_array
          facet_value_array.each do |facet_value_item|
            node[attribute_group_name] = {} unless node[attribute_group_name]
            node[attribute_group_name][facet_value_item] = {} unless node[attribute_group_name][facet_value_item]
            set_facet_attribute(node[attribute_group_name][facet_value_item], path_array[1..-1], value)
          end
        else
          node[attribute_group_name] = {} unless node[attribute_group_name]
          node[attribute_group_name][facet_value] = {} unless node[attribute_group_name][facet_value]
          set_facet_attribute(node[attribute_group_name][facet_value], path_array[1..-1], value)
        end
      end

      def get_tag_value(input_tags_array, tag_value_match)
        input_tags_array.each do |tag|
          return tag['Value'] if tag['Key'] == tag_value_match
        end
      end
    end
  end
end
