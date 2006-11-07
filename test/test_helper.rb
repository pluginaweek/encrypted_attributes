plugin_path = File.join(File.dirname(__FILE__), '..')
test_path = File.join(plugin_path, 'test')

$:.unshift(File.join(plugin_path, 'lib'))

# Find the root path of the application and boot it up
if (root_path = ENV['RAILS_ROOT']).nil?
  unless defined?(RAILS_ROOT)
    root_path = File.dirname(File.expand_path(__FILE__))
    while (boot_paths = Dir[File.join(root_path, 'config', 'boot{,.rb}')]).empty?
      root_path = File.dirname(root_path)
    end
  end
end
require File.join(root_path, 'config', 'boot')

require 'rubygems'
require 'test/unit'
require File.expand_path(File.join(RAILS_ROOT, 'config', 'environment.rb'))
require 'active_record/fixtures'
require 'active_support/binding_of_caller'
require 'active_support/breakpoint'

# Configure the database
config = YAML::load(IO.read(File.join(test_path, 'database.yml')))
ActiveRecord::Base.logger = Logger.new(File.join(test_path, 'debug.log'))
ActiveRecord::Base.establish_connection(config[ENV['DB'] || 'sqlite3'])

# Load additional tables just for testing
schema_path = File.join(test_path, 'schema.rb')
load(schema_path) if File.exist?(schema_path)

# Setup test cases for fixture support
Test::Unit::TestCase.fixture_path = File.join(test_path, 'fixtures', '')
$LOAD_PATH.unshift(Test::Unit::TestCase.fixture_path)

class Test::Unit::TestCase #:nodoc:
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
  
  def create_fixtures(*table_names)
    if block_given?
      Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names) { yield }
    else
      Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names)
    end
  end
end