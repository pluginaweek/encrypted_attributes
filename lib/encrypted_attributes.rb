require 'encrypted_strings'
require 'encrypted_attributes/extensions/encryptor'
require 'encrypted_attributes/extensions/sha_encryptor'

module PluginAWeek #:nodoc:
  module EncryptedAttributes
    def self.included(base) #:nodoc:
      base.extend(MacroMethods)
    end
    
    module MacroMethods
      # Encrypts the specified attribute.
      # 
      # Configuration options:
      # * +mode+ - The mode of encryption to use.  Default is sha.
      # * +crypted_name+ - The name of the attribute to store the crypted value in.  Default is "crypted_#{attr_name}".
      # 
      # For additional configuration options, see the individual encryptor class.
      def encrypts(attr_name, options = {})
        mode = options.delete(:mode) || :sha
        encryptor_class = "PluginAWeek::EncryptedStrings::#{mode.to_s.classify}Encryptor".constantize
        
        options.reverse_merge!(
          :crypted_name => "crypted_#{attr_name}"
        )
        crypted_attr_name = options.delete(:crypted_name)
        raise ArgumentError, 'Attribute name cannot be same as crypted name' if attr_name == crypted_attr_name
        
        # Creator accessor for the virtual attribute
        attr_accessor attr_name
        
        # Define the reader when reading the crypted value from the db
        crypted_var_name = "@#{crypted_attr_name}"
        define_method(crypted_attr_name) do
          if (value = read_attribute(crypted_attr_name)) && !value.encrypted?
            encryptor_options = options.dup
            encryptor_class.process_options(self, :read, encryptor_options)
            value.encryptor = encryptor_class.new(encryptor_options)
          end
          
          value
        end
        
        # Set the value immediately before validation takes place
        before_validation do |model|
          value = model.send(attr_name)
          
          if !value.blank?
            unless value.encrypted?
              encryptor_options = options.dup
              encryptor_class.process_options(model, :write, encryptor_options)
              value = value.encrypt(mode, encryptor_options)
            end
            
            model.send("#{crypted_attr_name}=", value)
          end
        end
        
        # After saving, be sure to reset the virtual attribute value.  This also
        # supported resetting the confirmation field if, for example, the plugin
        # is being used for passwords
        after_save do |model|
          model.send("#{attr_name}=", nil)
          model.send("#{attr_name}_confirmation=", nil) if model.respond_to?("#{attr_name}_confirmation=")
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include PluginAWeek::EncryptedAttributes
end
