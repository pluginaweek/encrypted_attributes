# Load the plugin testing framework
$:.unshift("#{File.dirname(__FILE__)}/../../plugin_test_helper/lib")
require 'rubygems'

gem 'encrypted_strings'
require 'plugin_test_helper'

# Run the migrations
ActiveRecord::Migrator.migrate("#{Rails.root}/db/migrate")

# Mixin the factory helper
require File.expand_path("#{File.dirname(__FILE__)}/factory")
Test::Unit::TestCase.class_eval do
  include Factory
end
