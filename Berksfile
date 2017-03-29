source 'https://api.berkshelf.com'

cookbook 'file', git: 'https://github.com/jenssegers/chef-patch', tag: 'v1.0.0'

cookbook 'maven', git: 'git://github.com/maoo/maven.git', tag: 'v1.2.0-fork'

group :integration do
  cookbook 'commons_test', path: './test/cookbooks/commons_test'
end

metadata
