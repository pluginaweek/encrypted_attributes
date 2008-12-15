module EncryptedAttributes
  # Adds support for dynamically generated salts
  class ShaCipher < EncryptedStrings::ShaCipher
    # Encrypts a string using a Secure Hash Algorithm (SHA), specifically SHA-1.
    # 
    # The <tt>:salt</tt> configuration option can be any one of the following types:
    # * +symbol+ - Calls the method on the object whose value is being encrypted
    # * +proc+ - A block that will be invoked, providing it with the object whose value is being encrypted
    # * +string+ - The actual salt value to use
    def initialize(object, value, operation, options = {}) #:nodoc:
      if operation == :write
        # Figure out the actual salt value
        if salt = options[:salt]
          options[:salt] =
            case salt
            when Symbol
              object.send(salt)
            when Proc
              salt.call(object)
            else
              salt
            end
        end
        
        # Track whether or not the salt was generated dynamically
        @dynamic_salt = salt != options[:salt]
        
        super(options)
      else
        # The salt is at the end of the value if it's dynamic
        salt = value[40..-1]
        if @dynamic_salt = !salt.blank?
          options[:salt] = salt 
        end
        
        super(options)
      end
    end
    
    # Encrypts the data, appending the salt to the end of the string if it
    # was created dynamically
    def encrypt(data)
      encrypted_data = super
      encrypted_data << salt if @dynamic_salt
      encrypted_data
    end
  end
end
