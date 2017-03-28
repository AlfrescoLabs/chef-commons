maven_setup 'setup maven' do
  maven_home node['maven']['m2_home']
  only_if { node['commons']['install_maven'] }
end

artifact 'deploy artifacts' do
  repos_databag 'maven_repos'
  property_equals_sign ':'
  term_delimiter_start '('
  term_delimiter_end ')'
  attribute_repos node['commons']['maven']['repositories']
  chef_cache node['commons']['cache_folder']
  pathPrefix node['artifactPathPrefix']
  artifacts node['artifacts']
end
