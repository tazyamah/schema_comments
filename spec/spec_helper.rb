if ENV["COVERAGE"] and not(ENV["COVERAGE"].empty?)
  require "simplecov"
  SimpleCov.start
end

ENV['DB'] ||= 'sqlite3'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rails'
require 'schema_comments'
# require 'database_cleaner'
SchemaComments.yaml_path = File.expand_path("schema_comments.yml", File.dirname(__FILE__))

# Ensure we use 'syck' instead of 'psych' in 1.9.2
# RubyGems >= 1.5.0 uses 'psych' on 1.9.2, but
# Psych does not yet support YAML 1.1 merge keys.
# Merge keys is often used in mongoid.yml
# See: http://redmine.ruby-lang.org/issues/show/4300
# if RUBY_VERSION >= '1.9.2'

# if defined?(YAML::ENGINE) && YAML::ENGINE.respond_to?(:yamler=)
#   YAML::ENGINE.yamler = 'syck'
# end

# require 'yaml_waml'

require 'fake_app'

require 'rspec/rails'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}


RSpec.configure do |config|

  %w(resources/models).each do |path|
    $LOAD_PATH.unshift File.join(File.dirname(__FILE__), path)
    ActiveSupport::Dependencies.autoload_paths << File.join(File.dirname(__FILE__), path)
  end
  Dir.glob("resources/**/*.rb") do |filename|
    require filename
  end

  SchemaComments.setup
end

MIGRATIONS_ROOT = File.join(File.dirname(__FILE__), 'migrations')

IGNORED_TABLES = %w(schema_migrations)
