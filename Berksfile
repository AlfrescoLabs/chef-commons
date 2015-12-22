source "https://api.berkshelf.com"

cookbook 'maven', git: 'git://github.com/maoo/maven.git', tag: "v1.2.0-fork"
cookbook 'file', git: 'git://github.com/jenssegers/chef-filehelper.git', tag: "v1.0.0"

group :integration do
  cookbook 'commons_test', :path => './test/cookbooks/commons_test'
end

metadata
