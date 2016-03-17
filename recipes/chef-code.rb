cookbook_path = node['commons']['cookbook_path']
source_cookbook_path = node['commons']['source_cookbook_path']
if source_cookbook_path
  directory cookbook_path do
    action :create
  end
  execute "create-#{cookbook_path}" do
    command "rm -rf #{cookbook_path} ; cp -rf #{source_cookbook_path} #{cookbook_path}"
    # Force override
    # not_if "test -d #{cookbook_path}"
  end
end

data_bag_path = node['commons']['data_bag_path']
source_data_bag_path = node['commons']['source_data_bag_path']
if source_data_bag_path
  directory data_bag_path do
    action :create
  end
  execute "create-#{data_bag_path}" do
    command "rm -rf #{data_bag_path} ; cp -rf #{source_data_bag_path} #{data_bag_path}"
    # Force override
    # not_if "test -d #{data_bag_path}"
  end
end
