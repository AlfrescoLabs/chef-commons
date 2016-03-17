hostname = node['hosts']['hostname']
domain = node['hosts']['domain']

node.set['hosts']['host_list']["#{hostname}.#{domain} #{hostname} localhost"] = "127.0.0.1"
hosts = node['hosts']['host_list']

file '/etc/hostname' do
  action :create
  content "#{hostname}.#{domain}"
end

# Always recreate /etc/hosts from scratch
file '/etc/hosts' do
  action :create
  content ""
end

hosts.each do |name,ip|
  replace_or_add "add-host-for-#{ip}" do
    path "/etc/hosts"
    pattern "#{ip} "
    line "#{ip} #{name}"
  end
end

execute "invoke-hostname-command" do
  command "hostname #{hostname}.#{domain}"
  not_if "hostname | grep #{hostname}.#{domain}"
end
