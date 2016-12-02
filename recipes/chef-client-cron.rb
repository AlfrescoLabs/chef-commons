cron_name = node['commons']['chef-client-cron']['cron_name']
chef_json_cookbook = node['commons']['chef-client-cron']['chef_json_cookbook']
chef_json_source = node['commons']['chef-client-cron']['chef_json_source']
chef_client_cron_path = "/etc/cron.d/#{cron_name}.cron"

if cron_name && chef_json_cookbook && chef_json_source
  chef_json_path = "#{node['commons']['chef-client-cron']['chef_json_path_prefix']}/#{cron_name}.json"
  node.default['commons']['chef-client-cron']['chef_json_path'] = chef_json_path

  directory File.dirname(chef_client_cron_path) do
    recursive true
    action :create
  end

  template chef_client_cron_path do
    source 'cron/chef-client.cron.erb'
  end

  directory File.dirname(chef_json_path) do
    recursive true
    action :create
  end

  template chef_json_path do
    source chef_json_source
    cookbook chef_json_cookbook
  end
end
