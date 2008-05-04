require 'encrypted_strings'
require 'encrypted_attributes/sha_encryptor'

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
      # * +to+ - The attribute to write the encrypted value. Default is the same attribute being encryupted.
      # * +if+ - Specifies a method, proc or string to call to determine if the encryption should occur. The method, proc or string should return or evaluate to a true or false value.
      # * +unless+ - Specifies a method, proc or string to call to determine if the encryption should not occur. The method, proc or string should return or evaluate to a true or false value. 
      # 
      # For additional configuration options, see the individual encryptor class.
      def encrypts(attr_name, options = {})
        attr_name = attr_name.to_s
        to_attr_name = options.delete(:to) || attr_name
        
        mode = options.delete(:mode) || :sha
        if mode == :sha
          encryptor_class = "PluginAWeek::EncryptedAttributes::#{mode.to_s.classify}Encryptor".constantize
        else
          encryptor_class = "PluginAWeek::EncryptedStrings::#{mode.to_s.classify}Encryptor".constantize
        end
        
        # Set the value immediately before validation takes place
        before_validation(:if => options.delete(:if), :unless => options.delete(:unless)) do |record|
          value = record.send(attr_name)
          
          unless value.blank? || value.encrypted?
            # Add contextual information for this plugin's encryptors
            encryptor =
              if encryptor_class.parent == PluginAWeek::EncryptedAttributes
                encryptor_class.new(record, value, :write, options.dup)
              else
                encryptor_class.new(options.dup)
              end
            
            # Encrypt the value and then track the encryptor used
            value = encryptor.encrypt(value)
            value.encryptor = encryptor
            
            record.send("#{to_attr_name}=", value)
          end
          
          true
        end
        
        # Define the reader when reading the crypted attribute from the db
        define_method(to_attr_name) do
          value = read_attribute(to_attr_name)
          
          # Make sure we set the encryptor for equality comparison when reading
          # from the database
          unless value.blank? || value.encrypted? || attribute_changed?(to_attr_name)
            # Add contextual information for this plugin's encryptors
            value.encryptor =
              if encryptor_class.parent == PluginAWeek::EncryptedAttributes
                encryptor_class.new(self, value, :read, options.dup)
              else
                encryptor_class.new(options.dup)
              end
          end
          
          value
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include PluginAWeek::EncryptedAttributes
end
