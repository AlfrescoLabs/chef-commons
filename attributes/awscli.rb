default['commons']['install_awscli'] = true
default['commons']['awscli']['aws_region'] = "us-east-1"
default['commons']['awscli']['credentials_parent_path'] = "/root/.aws"
default['commons']['awscli']['force_commandline_install'] = true
default['commons']['awscli']['aws_command'] = 'aws'


default['commons']['awscli']['credentials_databag'] = "aws"
default['commons']['awscli']['credentials_databag_item'] = "local"

default['commons']['restart_services'] = []
default['restart_services'] = ['tomcat7']

default['commons']['install_maven'] = true
default['commons']['maven']['repos_databag'] = "maven_repos"
default['commons']['maven']['master_password'] = ""
default['commons']['maven']['purge_settings'] = false
