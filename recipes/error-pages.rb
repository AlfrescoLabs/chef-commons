error_file_cookbook = node['errorpages']['error_file_cookbook']
error_file_source = node['errorpages']['error_file_source']
error_folder = node['errorpages']['error_folder']
hostname = node['errorpages']['public_hostname']

directory error_folder do
  action :create
  recursive true
end

%w( 400 403 404 408 500 502 503 504 ).each do |error_code|
  template "#{error_folder}/#{error_code}.http" do
    cookbook error_file_cookbook
    source "#{error_file_source}/#{error_code}.http.erb"
    variables(hostname: hostname)
  end
end
