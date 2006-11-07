require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.join(File.dirname(__FILE__), '..', 'fixtures', 'user')

class EncryptedAttributesTest < Test::Unit::TestCase
  def setup
    AsymmetricallyEncryptedString.default_private_key_file = File.join(File.dirname(__FILE__), '..', 'keys', 'private')
    AsymmetricallyEncryptedString.default_public_key_file = File.join(File.dirname(__FILE__), '..', 'keys', 'public')
    
    SymmetricallyEncryptedString.default_key = 'key'
  end
  
  def test_basic_encryption
    {
      SHAUser => SHAEncryptedString,
      AsymmetricUser => AsymmetricallyEncryptedString,
      SymmetricUser => SymmetricallyEncryptedString
    }.each do |user_class, encryption_class|
      user = user_class.new
      user.login = 'john doe'
      user.password = 'secret'
      
      assert user.save
      assert_not_nil user.crypted_password
      assert_instance_of encryption_class, user.crypted_password
    end
  end
  
  def test_encrypts_with_different_crypted_name
    user = SHAUserWithCustomCryptedAttr.new
    user.login = 'john doe'
    user.password = 'secret'
    
    assert user.save
    assert_nil user.crypted_password
    assert_not_nil user.protected_password
    assert_instance_of SHAEncryptedString, user.protected_password
  end
  
  def test_encrypt_on_invalid_model
    user = SHAUser.new
    user.login = nil
    user.password = 'secret'
    
    assert !user.save
    assert_not_nil user.password
    assert_not_nil user.crypted_password
    assert_instance_of SHAEncryptedString, user.crypted_password
  end
  
  def test_no_encryption_if_blank
    user = SHAUser.new
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
    
    user = SHAUser.new
    user.login = 'john doe'
    user.password = encrypted_password
    
    assert user.save
    assert_equal encrypted_password, user.crypted_password
  end
  
  def test_attribute_hidden_after_save
    user = SHAUser.new
    user.login = 'john doe'
    user.password = 'secret'
    
    assert user.save
    assert_nil user.password
  end
  
  def test_confirmation_hidden_after_save
    user = ConfirmedSHAUser.new
    user.login = 'john doe'
    user.password = 'secret'
    user.password_confirmation = 'secret'
    
    assert user.save
    assert_nil user.password
    assert_nil user.password_confirmation
  end
  
  def test_encrypts_sha_with_generated_salt
    user = SHAUserWithSalt.new
    user.login = 'john doe'
    user.password = 'secret'
    
    assert user.save
    assert_not_nil user.salt
    assert_equal 'john doe_salt', user.salt
    assert_equal 'secret', user.crypted_password
  end
  
  def test_returns_encrypted_password_on_saved_record
    user = SHAUser.new
    user.login = 'john doe'
    user.password = 'secret'
    
    assert user.save
    
    user = SHAUser.find(user.id)
    assert_nil user.password
    assert_not_nil user.crypted_password
    assert_instance_of SHAEncryptedString, user.crypted_password
  end
end
