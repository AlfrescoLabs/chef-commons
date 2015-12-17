resource_name :awscli

property :resource_title, String, name_property: true
property :aws_region, default: lazy { node['artifact-deployer']['awscli']['aws_region'] }
property :credentials_databag, default: lazy { node['artifact-deployer']['awscli']['credentials_databag'] }
property :credentials_databag_item, String, default: lazy { node['artifact-deployer']['awscli']['credentials_databag_item'] }
property :credentials_parent_path, default: lazy { node['artifact-deployer']['awscli']['credentials_parent_path'] }
property :force_cmd, default: lazy { node['artifact-deployer']['force_awscli_commandline_install'] }
property :aws_config_file, default: lazy { "#{node['artifact-deployer']['awscli']['credentials_parent_path']}/credentials" }

action :create do
  if force_cmd
    package 'python-pip' do
      action :install
    end
    execute 'install-awscli' do
      command 'pip install awscli'
      not_if 'pip list | grep awscli'
    end
  else
    include_recipe 'python::default'
    python_pip 'awscli'
  end

  directory credentials_parent_path do
    mode '0755'
    action :create
  end

  begin
    aws_credentials = data_bag_item(credentials_databag,credentials_databag_item)
    aws_config = "[default]
region=#{aws_region}
aws_access_key_id=#{aws_credentials['aws_access_key_id']}
aws_secret_access_key=#{aws_credentials['aws_secret_access_key']}"

    file aws_config_file do
      content aws_config
    end
  rescue
    Chef::Log.warn("Cannot find databag "+credentials_databag+" with item "+
    credentials_databag_item+"; skipping "+aws_config_file+ " file creation")
  end
end
