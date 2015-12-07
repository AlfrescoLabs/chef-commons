# commons::databags-to-files creates files from databags (duh)
# It loads all databags configued in the attributes and creates
# a file for each JSON element defined within the databag item(s).
# The JSON element name defines the file extension
#
# Example; given the following databag item:
# {
#   "id" : test,
#   "key1" : "value1",
#   "key2" : "value2",
# }
#
# the following files are created:
# /default/destination/folder/filename_prefix.key1 (with "value1" as content)
# /default/destination/folder/filename_prefix.key2 (with "value2" as content)
#
# Check attributes/databags-to-files.rb for all attribute configuration options
#
default_destination_folder = node['commons']['databags_to_files']['default_destination_folder']
default_filename_prefix = node['commons']['databags_to_files']['default_filename_prefix']
databags = node['commons']['databags_to_files']['databags']

if databags
  databags.each do |databag_name,databag_items|
    databag_items.each do |databag_item_name,databag_item|
      destination_folder = databag_item['destination_folder'] || default_destination_folder
      filename_prefix = databag_item['filename_prefix'] || default_filename_prefix

      Application.fatal!("Cannot find databag destination_folder or filename_prefix on commons::databags_to_files recipe for databag #{databag_name}/#{databag_item_name}") unless destination_folder or filename_prefix

      directory destination_folder do
        action :create
        recursive true
      end

      begin
        data_bag_item_content = data_bag_item(databag_name,databag_item_name)
        Chef::Log.info("Found databag #{databag_name}/#{databag_item_name}; parsing now")
        data_bag_item_content.each do |attribute_name,attribute_value|
          unless attribute_name == "id"
            attribute_output_file = "#{destination_folder}/#{filename_prefix}.#{attribute_name}"
            file attribute_output_file do
              action :create
              content attribute_value
            end
            Chef::Log.info("Created file #{attribute_output_file}")
          end
        end
      rescue
        Chef::Log.error("Cannot find databag #{databag_name}/#{databag_item_name}")
      end
    end
  end
end
