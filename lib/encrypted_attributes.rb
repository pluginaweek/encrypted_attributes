require 'encrypted_strings'

require File.join('encrypted_attributes', 'sha_encrypted_string')

module PluginAWeek #:nodoc:
  module EncryptedAttributes
    def self.included(base) #:nodoc:
      base.extend(MacroMethods)
    end
    
    module MacroMethods
      # Encrypts the specified attribute using the mode given in the configuration
      # options or, by default, SHA encryption.
      # 
      # Configuration options:
      # * <tt>mode</tt> - The mode of encryption to use
      # * <tt>crypted_name</tt> - The name of the attribute to store the crypted value in.  By default, this is "crypted_#{attr_name}"
      # 
      # For additional configuration options, see the individual encryption
      # class.
      # 
      def encrypts(attr_name, options = {})
        mode = options.delete(:mode) || :sha
        send("encrypts_#{mode}", attr_name, options)
      end
      
      # Encrypts the specified attribute using an SHA algorithm.
      # 
      # Configuration options:
      # * <tt>crypted_name</tt> - The name of the attribute to store the crypted value in.  By default, this is "crypted_#{attr_name}"
      # 
      # For additional configuration options, see the individual encryption
      # class.
      # 
      def encrypts_sha(attr_name, options = {})
        encrypts_with(attr_name, SHAEncryptedString, options)
      end
      
      # Encrypts the specified attribute using an asymmetric algorithm.  For
      # additional configuration options, see the individual encryption class.
      # 
      def encrypts_asymmetrically(attr_name, options = {})
        encrypts_with(attr_name, AsymmetricallyEncryptedString, options)
      end
      alias_method :encrypts_asmmetric, :encrypts_asymmetrically
      
      # Encrypts the specified attribute using a symmetric algorithm.  For
      # additional configuration options, see the individual encryption class.
      # 
      def encrypts_symmetrically(attr_name, options = {})
        encrypts_with(attr_name, SymmetricallyEncryptedString, options)
      end
      alias_method :encrypts_symmetric, :encrypts_symmetrically
      
      private
      def encrypts_with(attr_name, klass, options = {}) #:nodoc:
        options.reverse_merge!(
          :crypted_name => "crypted_#{attr_name}"
        )
        crypted_attr_name = options.delete(:crypted_name)
        raise ArgumentError, 'Attribute name cannot be same as crypted name' if attr_name == crypted_attr_name
        
        # Creator accessor for the virtual attribute
        attr_accessor attr_name
        
        # Define the reader when reading the crypted value from the db
        var_name = "@#{crypted_attr_name}"
        reader_options = options.dup
        reader_options[:encrypt] = false
        define_method(crypted_attr_name) do
          # Checks the following:
          # 1. Do we already have a variable @var_name?
          # 2. Has a value been set for the crypted attribute?
          # 3. Is the value an empty string?
          # 4. Is the value already an EncryptedString?
          # 
          # If none of these evaluate to true, then we create an encrypted string
          # based on the current value of the crypted attribute and store it in
          # the instance variable.
          # 
          # This is used mostly for when you've retrieved an existing record
          # from the database.
          if (data = instance_variable_get(var_name)).nil? && (data = read_attribute(crypted_attr_name)) && !data.blank? && !data.is_a?(klass)
            data = instance_variable_set(var_name, create_encrypted_string(klass, data, reader_options))
          end
          
          data
        end
        
        # Set the value immediately before validation takes place
        before_validation do |model|
          value = model.send(attr_name)
          
          if !value.blank?
            unless value.is_a?(EncryptedString)
              value = model.send(:create_encrypted_string, klass, value, options)
            end
            
            model.send("#{crypted_attr_name}=", value)
          end
        end
        
        # After saving, be sure to reset the virtual attribute value.  This also
        # supported resetting the confirmation field if, for example, the plugin
        # is being used for passwods
        after_save do |model|
          model.send("#{attr_name}=", nil)
          model.send("#{attr_name}_confirmation=", nil) if model.respond_to?("#{attr_name}_confirmation=")
        end
        
        include InstanceMethods unless self.included_modules.include?(InstanceMethods)
      end
    end
    
    module InstanceMethods #:nodoc:
      private
      def create_encrypted_string(klass, value, options)
        if klass.respond_to?(:process_options)
          options = options.dup
          klass.process_options(self, options)
        end
        
        klass.new(value, options)
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include PluginAWeek::EncryptedAttributes
end