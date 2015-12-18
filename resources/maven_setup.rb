resource_name :maven_setup

property :resource_title, String, name_property: true
property :maven_home, String, required: true
property :master_password, String, default: lazy { node['artifact-deployer']['maven']['master_password'] }
property :repos_databag, String, default: lazy { node['artifact-deployer']['maven']['repos_databag'] }
property :attribute_repos, String, default: lazy { node['artifact-deployer']['maven']['repositories'] }
property :purge_settings, kind_of: [TrueClass, FalseClass], default: lazy { node['artifact-deployer']['maven']['purge_settings'] || false }

default_action :create

action :create do

  # node.default['maven']['m2_home'] = maven_home

  include_recipe 'maven::default'

  maven_repos = []

  if attribute_repos
    attribute_repos.each do |repo_id, repo|
      mvnRepo = {}
      mvnRepo['id'] = repo_id
      repo.each do |param_name, param_value|
        mvnRepo[param_name] = param_value
      end
      maven_repos.push mvnRepo
    end
  end
  begin
    databag_repos = data_bag(repos_databag)

    if databag_repos
      databag_repos.each do |repo|
        repo_item = data_bag_item(repos_databag, repo)
        maven_repos.push repo_item
      end
    end
  rescue
    Chef::Log.warn('Cannot find databag ' + repos_databag + '; skipping Maven installation')
  end

  template "#{maven_home}/conf/settings.xml" do
    source 'maven/settings.xml.erb'
    mode 0666
    owner 'root'
    group 'root'
    variables(
      repos: maven_repos
    )
  end

  unless master_password.empty?
    directory '/root/.m2' do
      mode 0666
      owner 'root'
      group 'root'
    end

    template '/root/.m2/settings-security.xml' do
      source 'maven/settings-security.xml.erb'
      mode 0666
      owner 'root'
      group 'root'
    end
  end

  link '/usr/bin/mvn' do
    to "#{maven_home}/bin/mvn"
  end

  if purge_settings
    file "#{maven_home}/conf/settings.xml" do
      action :delete
    end
    directory '/root/.m2' do
      action :delete
      recursive true
    end
  end
end
