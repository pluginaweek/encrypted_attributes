require 'encrypted_strings'
require 'encrypted_attributes/sha_cipher'

module EncryptedAttributes
  module MacroMethods
    # Encrypts the given attribute.
    # 
    # Configuration options:
    # * <tt>:mode</tt> - The mode of encryption to use.  Default is <tt>:sha</tt>.
    #   See EncryptedStrings for other possible modes.
    # * <tt>:to</tt> - The attribute to write the encrypted value to. Default
    #   is the same attribute being encrypted.
    # * <tt>:before</tt> - The callback to invoke every time *before* the
    #   attribute is encrypted
    # * <tt>:after</tt> - The callback to invoke every time *after* the
    #   attribute is encrypted
    # * <tt>:on</tt> - The ActiveRecord callback to use when triggering the
    #   encryption.  By default, this will encrypt on <tt>before_validation</tt>.
    #   See ActiveRecord::Callbacks for a list of possible callbacks.
    # * <tt>:if</tt> - Specifies a method, proc or string to call to determine
    #   if the encryption should occur. The method, proc or string should return
    #   or evaluate to a true or false value.
    # * <tt>:unless</tt> - Specifies a method, proc or string to call to
    #   determine if the encryption should not occur. The method, proc or string
    #   should return or evaluate to a true or false value. 
    # 
    # For additional configuration options used during the actual encryption,
    # see the individual cipher class for the specified mode.
    # 
    # == Encryption timeline
    # 
    # By default, attributes are encrypted immediately before a record is
    # validated.  This means that you can still validate the presence of the
    # encrypted attribute, but other things like password length cannot be
    # validated without either (a) decrypting the value first or (b) using a
    # different encryption target.  For example,
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
    # 
    #   class User < ActiveRecord::Base
    #     encrypts :password
    #     # encrypts :password, :salt => 'secret'
    #   end
    # 
    # Symmetric encryption:
    # 
    #   class User < ActiveRecord::Base
    #     encrypts :password, :mode => :symmetric
    #     # encrypts :password, :mode => :symmetric, :key => 'custom'
    #   end
    # 
    # Asymmetric encryption:
    # 
    #   class User < ActiveRecord::Base
    #     encrypts :password, :mode => :asymmetric
    #     # encrypts :password, :mode => :asymmetric, :public_key_file => '/keys/public', :private_key_file => '/keys/private'
    #   end
    # 
    # == Dynamic configuration
    # 
    # For better security, the encryption options (such as the salt value)
    # can be based on values in each individual record.  In order to
    # dynamically configure the encryption options so that individual records
    # can be referenced, an optional block can be specified.
    # 
    # For example,
    # 
    #   class User < ActiveRecord::Base
    #     encrypts :password, :mode => :sha, :before => :create_salt do |user|
    #       {:salt => user.salt}
    #     end
    #     
    #     private
    #       def create_salt
    #         self.salt = "#{login}-#{Time.now}"
    #       end
    #   end
    # 
    # In the above example, the SHA encryption's <tt>salt</tt> is configured
    # dynamically based on the user's login and the time at which it was
    # encrypted.  This helps improve the security of the user's password.
    def encrypts(attr_name, options = {}, &config)
      config ||= options
      attr_name = attr_name.to_s
      to_attr_name = (options.delete(:to) || attr_name).to_s
      
      # Figure out what cipher is being configured for the attribute
      mode = options.delete(:mode) || :sha
      class_name = "#{mode.to_s.classify}Cipher"
      if EncryptedAttributes.const_defined?(class_name)
        cipher_class = EncryptedAttributes.const_get(class_name)
      else
        cipher_class = EncryptedStrings.const_get(class_name)
      end
      
      # Define encryption hooks
      define_callbacks("before_encrypt_#{attr_name}", "after_encrypt_#{attr_name}")
      send("before_encrypt_#{attr_name}", options.delete(:before)) if options.include?(:before)
      send("after_encrypt_#{attr_name}", options.delete(:after)) if options.include?(:after)
      
      # Set the encrypted value on the configured callback
      callback = options.delete(:on) || :before_validation
      send(callback, :if => options.delete(:if), :unless => options.delete(:unless)) do |record|
        record.send(:write_encrypted_attribute, attr_name, to_attr_name, cipher_class, config)
        true
      end
      
      # Define virtual source attribute
      if attr_name != to_attr_name && !column_names.include?(attr_name)
        attr_reader attr_name unless method_defined?(attr_name)
        attr_writer attr_name unless method_defined?("#{attr_name}=")
      end
      
      # Define the reader when reading the encrypted attribute from the database
      define_method(to_attr_name) do
        read_encrypted_attribute(to_attr_name, cipher_class, config)
      end
      
      unless included_modules.include?(EncryptedAttributes::InstanceMethods)
        include EncryptedAttributes::InstanceMethods
      end
    end
  end
  
  module InstanceMethods #:nodoc:
    private
      # Encrypts the given attribute to a target location using the encryption
      # options configured for that attribute
      def write_encrypted_attribute(attr_name, to_attr_name, cipher_class, options)
        value = send(attr_name)
        
        # Only encrypt values that actually have content and have not already
        # been encrypted
        unless value.blank? || value.encrypted?
          callback("before_encrypt_#{attr_name}")
          
          # Create the cipher configured for this attribute
          cipher = create_cipher(cipher_class, options, value)
          
          # Encrypt the value
          value = cipher.encrypt(value)
          value.cipher = cipher
          
          # Update the value based on the target attribute
          send("#{to_attr_name}=", value)
          
          callback("after_encrypt_#{attr_name}")
        end
      end
      
      # Reads the given attribute from the database, adding contextual
      # information about how it was encrypted so that equality comparisons
      # can be used
      def read_encrypted_attribute(to_attr_name, cipher_class, options)
        value = read_attribute(to_attr_name)
        
        # Make sure we set the cipher for equality comparison when reading
        # from the database. This should only be done if the value is *not*
        # blank, is *not* encrypted, and hasn't changed since it was read from
        # the database. The dirty checking is important when the encypted value
        # is written to the same attribute as the unencrypted value (i.e. you
        # don't want to encrypt when a new value has been set)
        unless value.blank? || value.encrypted? || attribute_changed?(to_attr_name)
          # Create the cipher configured for this attribute
          value.cipher = create_cipher(cipher_class, options, value)
        end
        
        value
      end
      
      # Creates a new cipher with the given configuration options
      def create_cipher(klass, options, value)
        options = options.is_a?(Proc) ? options.call(self) : options.dup
        
        # Only use the contextual information for this plugin's ciphers
        klass.parent == EncryptedAttributes ? klass.new(value, options) : klass.new(options)
      end
  end
end

ActiveRecord::Base.class_eval do
  extend EncryptedAttributes::MacroMethods
end
