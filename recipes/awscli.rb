if node['genius']['install_awscli']

  aws_region = node['genius']['awscli']['aws_region']
  aws_access_key_id = node['genius']['awscli']['aws_access_key_id']
  aws_secret_access_key = node['genius']['awscli']['aws_secret_access_key']

  credentials_databag = node['genius']['awscli']['credentials_databag']
  credentials_databag_item = node['genius']['awscli']['credentials_databag_item']
  credentials_parent_path = node['genius']['awscli']['credentials_parent_path']
  aws_config_file = "#{credentials_parent_path}/credentials"

  if node['genius']['awscli']['force_commandline_install']
    execute "install-awscli" do
      command "pip install awscli"
      not_if "pip list | grep awscli"
    end
  else
    include_recipe 'python::default'
    python_pip "awscli"
  end

  unless aws_access_key_id or aws_secret_access_key
    begin
      aws_credentials = data_bag_item(credentials_databag,credentials_databag_item)
      aws_access_key_id = aws_credentials['aws_access_key_id']
      aws_secret_access_key = aws_credentials['aws_secret_access_key']
    rescue
      Chef::Log.warn("genius::awscli cannot find databag '"+credentials_databag+"' with item '"+
      credentials_databag_item+"'; skipping "+aws_config_file+ " file creation")
    end
  end

  if aws_region and aws_access_key_id and aws_secret_access_key
    aws_config = "[default]
region=#{aws_region}
aws_access_key_id=#{aws_access_key_id}
aws_secret_access_key=#{aws_secret_access_key}"
    directory credentials_parent_path do
      mode '0700'
      action :create
      not_if { File.exist?(credentials_parent_path)}
    end
    file aws_config_file do
      content aws_config
    end
  else
    Chef::Log.warn("genius::awscli couldn't find a databag or access/secret keys as attributed; as a result, #{aws_config_file} have not been created")
  end
end
