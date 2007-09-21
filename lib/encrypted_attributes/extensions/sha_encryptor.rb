module PluginAWeek #:nodoc:
  module EncryptedAttributes
    module Extensions #:nodoc:
      module ShaEncryptor
        # Adds support for using a salt that is generated based on the model and
        # stored in an attribute.
        def process_options(model, operation, options)
          if (salt_attr_name = options[:salt]) && (salt_attr_name == true || salt_attr_name.is_a?(Symbol))
            salt_attr_name = 'salt' if salt_attr_name == true
            
            if operation == :write
              salt_value = model.send("create_#{salt_attr_name}").to_s
              model.send("#{salt_attr_name}=", salt_value)
            else
              salt_value = model.send(salt_attr_name)
            end
            
            options[:salt] = salt_value
          end
        end
      end
    end
  end
end

PluginAWeek::EncryptedStrings::ShaEncryptor.class_eval do
  extend PluginAWeek::EncryptedAttributes::Extensions::ShaEncryptor
end
