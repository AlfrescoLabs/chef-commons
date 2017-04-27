source 'https://rubygems.org'

# Used by Travis

gem 'chef', '~>12'
gem 'chef-zero', '~>5'
gem 'chef-config', '~>12'
gem 'inspec', '~>1.2.1'
gem 'foodcritic', '~> 10.2.0'
gem 'cookstyle', '~> 1.2.0'
gem 'berkshelf', '~> 5.1.0'
gem 'chefspec', '~> 4.5.0'
gem 'simplecov', '~> 0.12.0'
gem 'simplecov-rcov', '~> 0.2.3'
gem 'rake'
gem 'aws-sdk', '~> 2'

group :docker do
  gem 'test-kitchen', '~> 1.4'
  gem 'kitchen-docker', '~> 2.6.0'
  gem 'kitchen-inspec', '~> 0.16.1'
end

group :vagrant do
  gem 'vagrant-wrapper', '~> 2.0'
  gem 'kitchen-vagrant', '~> 0.18'
end

group :development do
  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-rubocop'
  gem 'guard-foodcritic', '~> 3.0.0'
end
