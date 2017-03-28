m2_home                  = node['maven']['m2_home']
credentials_parent_path  = node['artifact-deployer']['awscli']['credentials_parent_path']
purge_settings           = node['artifact-deployer']['maven']['purge_settings']

include_recipe 'artifact-deployer::maven'
include_recipe 'artifact-deployer::artifacts'

if purge_settings == true
  file "#{m2_home}/conf/settings.xml" do
    action :delete
  end
  directory '/root/.m2' do
    action :delete
    recursive true
  end
  directory credentials_parent_path do
    action :delete
    recursive true
  end
end
