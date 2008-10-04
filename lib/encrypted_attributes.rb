require 'encrypted_strings'
require 'encrypted_attributes/sha_encryptor'

module PluginAWeek #:nodoc:
  module EncryptedAttributes
    module MacroMethods
      # Encrypts the specified attribute.
      # 
      # Configuration options:
      # * +mode+ - The mode of encryption to use.  Default is sha. See PluginAWeek::EncryptedStrings for other possible modes
      # * +to+ - The attribute to write the encrypted value to. Default is the same attribute being encrypted.
      # * +if+ - Specifies a method, proc or string to call to determine if the encryption should occur. The method, proc or string should return or evaluate to a true or false value.
      # * +unless+ - Specifies a method, proc or string to call to determine if the encryption should not occur. The method, proc or string should return or evaluate to a true or false value. 
      # 
      # For additional configuration options used during the actual encryption,
      # see the individual encryptor class for the specified mode.
      # 
      # == Encryption timeline
      # 
      # Attributes are encrypted immediately before a record is validated.
      # This means that you can still validate the presence of the encrypted
      # attribute, but other things like password length cannot be validated
      # without either (a) decrypting the value first or (b) using a different
      # encryption target.  For example,
      # 
      #   class User < ActiveRecord::Base
      #     encrypts :password, :to => :crypted_password
      #     
      #     validates_presence_of :password, :crypted_password
      #     validates_length_of :password, :maximum => 16
      #   end
      # 
      # In the above example, the actual encrypted password will be stored in
      # the +crypted_password+ attribute.  This means that validations can
      # still run against the model for the original password value.
      # 
      #   user = User.new(:password => 'secret')
      #   user.password             # => "secret"
      #   user.crypted_password     # => nil
      #   user.valid?               # => true
      #   user.crypted_password     # => "8152bc582f58c854f580cb101d3182813dec4afe"
      #   
      #   user = User.new(:password => 'longer_than_the_maximum_allowed')
      #   user.valid?               # => false
      #   user.crypted_password     # => "e80a709f25798f87d9ca8005a7f64a645964d7c2"
      #   user.errors[:password]    # => "is too long (maximum is 16 characters)"
      # 
      # == Encryption mode examples
      # 
      # SHA encryption:
      #   class User < ActiveRecord::Base
      #     encrypts :password
      #     # encrypts :password, :salt => :create_salt
      #   end
      # 
      # Symmetric encryption:
      #   class User < ActiveRecord::Base
      #     encrypts :password, :mode => :symmetric
      #     # encrypts :password, :mode => :symmetric, :key => 'custom'
      #   end
      # 
      # Asymmetric encryption:
      #   class User < ActiveRecord::Base
      #     encrypts :password, :mode => :asymmetric
      #     # encrypts :password, :mode => :asymmetric, :public_key_file => '/keys/public', :private_key_file => '/keys/private'
      #   end
      def encrypts(attr_name, options = {})
        attr_name = attr_name.to_s
        to_attr_name = options.delete(:to) || attr_name
        
        # Figure out what encryptor is being configured for the attribute
        mode = options.delete(:mode) || :sha
        class_name = "#{mode.to_s.classify}Encryptor"
        if PluginAWeek::EncryptedAttributes.const_defined?(class_name)
          encryptor_class = PluginAWeek::EncryptedAttributes.const_get(class_name)
        else
          encryptor_class = PluginAWeek::EncryptedStrings.const_get(class_name)
        end
        
        # Set the encrypted value right before validation takes place
        before_validation(:if => options.delete(:if), :unless => options.delete(:unless)) do |record|
          record.send(:write_encrypted_attribute, attr_name, to_attr_name, encryptor_class, options)
          true
        end
        
        # Define the reader when reading the encrypted attribute from the database
        define_method(to_attr_name) do
          read_encrypted_attribute(to_attr_name, encryptor_class, options)
        end
        
        unless included_modules.include?(PluginAWeek::EncryptedAttributes::InstanceMethods)
          include PluginAWeek::EncryptedAttributes::InstanceMethods
        end
      end
    end
    
    module InstanceMethods #:nodoc:
      private
        # Encrypts the given attribute to a target location using the encryption
        # options configured for that attribute
        def write_encrypted_attribute(attr_name, to_attr_name, encryptor_class, options)
          value = send(attr_name)
          
          # Only encrypt values that actually have content and have not already
          # been encrypted
          unless value.blank? || value.encrypted?
            # Create the encryptor configured for this attribute
            encryptor = create_encryptor(encryptor_class, options, :write, value)
            
            # Encrypt the value
            value = encryptor.encrypt(value)
            value.encryptor = encryptor
            
            # Update the value based on the target attribute
            send("#{to_attr_name}=", value)
          end
        end
        
        # Reads the given attribute from the database, adding contextual
        # information about how it was encrypted so that equality comparisons
        # can be used
        def read_encrypted_attribute(to_attr_name, encryptor_class, options)
          value = read_attribute(to_attr_name)
          
          # Make sure we set the encryptor for equality comparison when reading
          # from the database. This should only be done if the value is *not*
          # blank, is *not* encrypted, and hasn't changed since it was read from
          # the database. The dirty checking is important when the encypted value
          # is written to the same attribute as the unencrypted value (i.e. you
          # don't want to encrypt when a new value has been set)
          unless value.blank? || value.encrypted? || attribute_changed?(to_attr_name)
            # Create the encryptor configured for this attribute
            value.encryptor = create_encryptor(encryptor_class, options, :read, value)
          end
          
          value
        end
        
        # Creates a new encryptor with the given configuration options. The
        # operator defines the context in which the encryptor will be used.
        def create_encryptor(klass, options, operator, value)
          if klass.parent == PluginAWeek::EncryptedAttributes
            # Only use the contextual information for encryptors defined in this plugin
            klass.new(self, value, operator, options.dup)
          else
            klass.new(options.dup)
          end
        end
    end
  end
end

ActiveRecord::Base.class_eval do
  extend PluginAWeek::EncryptedAttributes::MacroMethods
end
