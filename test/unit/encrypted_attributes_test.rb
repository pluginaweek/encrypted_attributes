require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))

class EncryptedAttributesTest < Test::Unit::TestCase
  def setup
    PluginAWeek::EncryptedStrings::AsymmetricEncryptor.default_private_key_file = File.join(File.dirname(__FILE__), '..', 'keys', 'private')
    PluginAWeek::EncryptedStrings::AsymmetricEncryptor.default_public_key_file = File.join(File.dirname(__FILE__), '..', 'keys', 'public')
    
    PluginAWeek::EncryptedStrings::SymmetricEncryptor.default_key = 'key'
  end
  
  def test_basic_encryption
    {
      ShaUser => PluginAWeek::EncryptedStrings::ShaEncryptor,
      AsymmetricUser => PluginAWeek::EncryptedStrings::AsymmetricEncryptor,
      SymmetricUser => PluginAWeek::EncryptedStrings::SymmetricEncryptor
    }.each do |user_class, encryptor_class|
      user = user_class.new
      user.login = 'john doe'
      user.password = 'secret'
      
      assert user.save
      assert_not_nil user.crypted_password
      assert user.crypted_password.encrypted?
      assert_instance_of encryptor_class, user.crypted_password.encryptor
    end
  end
  
  def test_encrypts_with_different_crypted_name
    user = ShaUserWithCustomCryptedAttr.new
    user.login = 'john doe'
    user.password = 'secret'
    
    assert user.save
    assert_nil user.crypted_password
    assert_not_nil user.protected_password
    assert user.protected_password.encrypted?
    assert_instance_of PluginAWeek::EncryptedStrings::ShaEncryptor, user.protected_password.encryptor
  end
  
  def test_encrypt_on_invalid_model
    user = ShaUser.new
    user.login = nil
    user.password = 'secret'
    
    assert !user.save
    assert_not_nil user.password
    assert_not_nil user.crypted_password
    assert user.crypted_password.encrypted?
    assert_instance_of PluginAWeek::EncryptedStrings::ShaEncryptor, user.crypted_password.encryptor
  end
  
  def test_no_encryption_if_blank
    user = ShaUser.new
    user.login = 'john doe'
    user.password = nil
    user.save
    assert_nil user.crypted_password
    
    user.password = ''
    assert user.save
    assert_nil user.crypted_password
  end
  
  def test_no_encryption_if_already_encrypted
    encrypted_password = 'secret'.encrypt
    
    user = ShaUser.new
    user.login = 'john doe'
    user.password = encrypted_password
    
    assert user.save
    assert_equal encrypted_password, user.crypted_password
  end
  
  def test_attribute_hidden_after_save
    user = ShaUser.new
    user.login = 'john doe'
    user.password = 'secret'
    
    assert user.save
    assert_nil user.password
  end
  
  def test_confirmation_hidden_after_save
    user = ConfirmedShaUser.new
    user.login = 'john doe'
    user.password = 'secret'
    user.password_confirmation = 'secret'
    
    assert user.save
    assert_nil user.password
    assert_nil user.password_confirmation
  end
  
  def test_encrypts_sha_with_generated_salt
    user = ShaUserWithSalt.new
    user.login = 'john doe'
    user.password = 'secret'
    
    assert user.save
    assert_not_nil user.salt
    assert_equal 'john doe_salt', user.salt
    assert_equal 'secret', user.crypted_password
  end
  
  def test_encrypts_sha_with_custom_generated_salt
    user = ShaUserWithCustomSalt.new
    user.login = 'john doe'
    user.password = 'secret'
    
    assert user.save
    assert_not_nil user.salt_value
    assert_equal 'john doe_salt_value', user.salt_value
    assert_equal 'secret', user.crypted_password
  end
  
  def test_returns_encrypted_password_on_saved_record
    user = ShaUser.new
    user.login = 'john doe'
    user.password = 'secret'
    
    assert user.save
    
    user = ShaUser.find(user.id)
    assert_nil user.password
    assert_not_nil user.crypted_password
    assert user.crypted_password.encrypted?
    assert_instance_of PluginAWeek::EncryptedStrings::ShaEncryptor, user.crypted_password.encryptor
  end
end
