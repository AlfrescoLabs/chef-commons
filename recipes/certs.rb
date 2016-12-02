create_certs 'Create/Download alfresco certificates' do
  ssl_filename node['certs']['filename']
  ssl_fqdn node['certs']['ssl_fqdn']
  ssl_folder node['certs']['ssl_folder']
  ssl_databag node['certs']['ssl_databag']
  ssl_databag_item node['certs']['ssl_databag_item']
  skip_certificate_creation node['certs']['skip_certificate_creation']
  action :run
end
