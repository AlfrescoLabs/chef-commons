name             "commons"
maintainer       "Alfresco"
maintainer_email ""
license          "Apache 2.0"
description      "Installs Alfresco Community and Enterprise Edition."
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version "0.0.1"

# Community cookbooks
depends "python", ">= 1.4.6"
# depends 'build-essential', ">= 2.2.3"
# depends "java", ">= 1.31.0"
# depends "openssl", ">= 4.0.0"
# depends 'yum-epel'
# depends 'yum-repoforge', ">= 0.5.1"
# depends 'yum-atrpms', ">= 0.1.0"


depends "maven", '~> 1.2.0'
depends 'apt', ">= 2.3.10"
depends "ark", ">= 0.9.0"
depends "resolver", ">= 1.2.0"
depends "java", ">= 1.31.0"
