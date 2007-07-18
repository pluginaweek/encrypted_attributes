class ShaUserWithCustomCryptedAttr < User
  encrypts :password, :crypted_name => 'protected_password'
end
