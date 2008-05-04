module PluginAWeek #:nodoc:
  module EncryptedAttributes
    # Supports encryption for ActiveRecord models by adding dynamically generated
    # salts
    class ShaEncryptor < PluginAWeek::EncryptedStrings::ShaEncryptor
      def initialize(record, value, operation, options = {}) #:nodoc:
        if operation == :write
          # Figure out the actual salt value
          if salt = options[:salt]
            options[:salt] =
              case salt
              when Symbol
                record.send(salt).to_s
              when Proc
                salt.call(record).to_s
              else
                salt
              end
          end
          
          @dynamic_salt = salt != options[:salt]
          super(options)
        else
          # The salt is in the value if it's dynamic
          salt = value[40..-1]
          if @dynamic_salt = !salt.blank?
            options.merge!(:salt => salt) 
          end
          
          super(options)
        end
      end
      
      # Encrypts the data, appending the salt to the end of the string
      def encrypt(data)
        encrypted_data = Digest::SHA1.hexdigest(data + salt)
        encrypted_data << salt if @dynamic_salt
        encrypted_data
      end
    end
  end
end
