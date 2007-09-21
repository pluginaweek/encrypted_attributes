module PluginAWeek #:nodoc:
  module EncryptedAttributes
    module Extensions #:nodoc:
      module Encryptor #:nodoc:
        def process_options(model, operation, options)
        end
      end
    end
  end
end

PluginAWeek::EncryptedStrings::Encryptor.class_eval do
  extend PluginAWeek::EncryptedAttributes::Extensions::Encryptor
end
