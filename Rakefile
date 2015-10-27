require 'rake'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts 'Run `bundle install` to install missing gems'
  exit e.status_code
end

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  # rspec not available - we're probably on a prod environment or need to run bundle install
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop)

begin
  require 'yard'
  YARD::Rake::YardocTask.new
  task doc: :yard
rescue LoadError
  desc 'Generate YARD Documentation'
  task :doc do
    abort 'Please install the YARD gem to generate rdoc.'
  end
end

task default: [:spec, :rubocop]
