name             'commons'
maintainer       'Alfresco TAA Team'
maintainer_email 'enzo.rivello@alfresco.com'
license          'Apache 2.0'
description      'Installs Alfresco Community and Enterprise Edition.'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))

version '0.5.4'
issues_url 'https://github.com/Alfresco/chef-commons/issues'
source_url 'https://github.com/Alfresco/chef-commons'

chef_version '~> 12'

supports 'centos', '>= 7.0'

# Community cookbooks
depends 'python', '>= 1.4.6'
depends 'chef-sugar', '>= 3.2.0'
depends 'line', '>= 0.6.3'
depends 'yum-epel', '>= 0.6.0'
depends 'artifact-deployer', '>=0.8.18'
# depends 'build-essential', '>= 2.2.3'
# depends 'java', '>= 1.31.0'
# depends 'openssl', '>= 4.0.0'
# depends 'yum-epel'
# depends 'yum-repoforge', '>= 0.5.1'
# depends 'yum-atrpms', '>= 0.1.0'

depends 'maven', '~> 1.2.0'
depends 'apt', '>= 2.3.10'
depends 'ark', '>= 0.9.0'
depends 'resolver', '>= 1.2.0'
depends 'java', '>= 1.31.0'
depends 'file', '>= 2.0.0'
