# commons::awscli installs and configures aws command
# It loads a databag to locate access key/secret and
# generates /root/.aws/credentials (configurable)
#
# You can also configure key and secret via Chef attributes, though databag,
# if specified, would overrule them
#
# Check attributes/awscli.rb for all attribute configuration options
#
if node['commons']['install_awscli']

  aws_region = node['commons']['awscli']['aws_region']
  aws_access_key_id = node['commons']['awscli']['aws_access_key_id']
  aws_secret_access_key = node['commons']['awscli']['aws_secret_access_key']

  credentials_databag = node['commons']['awscli']['credentials_databag']
  credentials_databag_item = node['commons']['awscli']['credentials_databag_item']
  credentials_parent_path = node['commons']['awscli']['credentials_parent_path']
  aws_config_file = "#{credentials_parent_path}/credentials"

  if node['commons']['awscli']['force_commandline_install']
    include_recipe 'yum-epel::default'
    package "python-pip" do
      action :install
    end
    execute "install-awscli" do
      command "pip install awscli --ignore-installed six"
      not_if "pip list | grep awscli"
    end
  else
    include_recipe 'python::default'
    python_pip "awscli"
  end

  if credentials_databag and credentials_databag_item
    begin
      aws_credentials = data_bag_item(credentials_databag,credentials_databag_item)
      aws_access_key_id = aws_credentials['aws_access_key_id']
      aws_secret_access_key = aws_credentials['aws_secret_access_key']
    rescue
      Chef::Log.warn("commons::awscli cannot find databag '"+credentials_databag+"' with item '"+
      credentials_databag_item+"'; skipping "+aws_config_file+ " file creation")
    end
  end

  if aws_access_key_id and aws_secret_access_key
    aws_config = "[default]
region=#{aws_region}
aws_access_key_id=#{aws_access_key_id}
aws_secret_access_key=#{aws_secret_access_key}"
    directory credentials_parent_path do
      mode '0600'
      action :create
      not_if { File.exist?(credentials_parent_path)}
    end
    file aws_config_file do
      content aws_config
    end
  else
    Chef::Log.warn("commons::awscli couldn't find a databag or access/secret keys as attributed; as a result, #{aws_config_file} have not been created")
  end
end
