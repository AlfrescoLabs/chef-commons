default['commons']['chef-client-cron']['chef_json_path_prefix'] = '/etc/chef'
default['commons']['chef-client-cron']['cron_command'] = 'cd /etc/chef; chef-client -z -j'
# Run every 5 minutes
default['commons']['chef-client-cron']['cron_expression'] = '*/5 * * * *'
default['commons']['chef-client-cron']['cron_user'] = 'root'
