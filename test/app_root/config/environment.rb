require 'config/boot'

Rails::Initializer.run do |config|
  config.plugin_paths << '..'
  config.plugins = %w(encrypted_strings encrypted_attributes)
  config.cache_classes = false
  config.whiny_nils = true
end
