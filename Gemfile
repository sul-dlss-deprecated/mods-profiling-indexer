source 'https://rubygems.org'

gem 'solrizer'
gem 'nokogiri'
gem 'rake'
gem 'rsolr'
gem 'trollop'
gem 'stanford-mods'

# sul-gems
# must have https for git so deployed instance can pull these gems
gem 'harvestdor', git: 'https://github.com/sul-dlss/harvestdor.git'
gem 'harvestdor-indexer', git: 'https://github.com/sul-dlss/harvestdor-indexer.git'
gem 'gdor-indexer', git: 'https://github.com/sul-dlss/gdor-indexer.git'

# documentation
group :doc do
  gem 'rdoc'
end

group :development do
  gem 'pry-byebug'
end

group :deployment do
  gem "capistrano", '~> 3.2'
  gem 'capistrano-bundler'
  gem "lyberteam-capistrano-devel"
  gem 'rainbow' # for color output
end

group :test do
  gem 'rspec'
  gem 'rubocop'
  gem 'rubocop-rspec'
  gem 'yard'  # for javadoc-y documentation tags
end