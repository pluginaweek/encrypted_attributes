require File.dirname(__FILE__) + '/../test_helper'

class ShaEncryptorOnWriteTest < Test::Unit::TestCase
  def setup
    @user = create_user(:login => 'admin')
  end
  
  def test_should_allow_symbolic_salt
    encryptor = PluginAWeek::EncryptedAttributes::ShaEncryptor.new(@user, 'password', :write, :salt => :login)
    assert_equal 'admin', encryptor.salt
  end
  
  def test_should_allow_stringified_salt
    encryptor = PluginAWeek::EncryptedAttributes::ShaEncryptor.new(@user, 'password', :write, :salt => 'custom_salt')
    assert_equal 'custom_salt', encryptor.salt
  end
  
  def test_should_allow_block_salt
    dynamic_salt = lambda {|user| user.login}
    encryptor = PluginAWeek::EncryptedAttributes::ShaEncryptor.new(@user, 'password', :write, :salt => dynamic_salt)
    assert_equal 'admin', encryptor.salt
  end
  
  def test_should_allow_dynamic_nil_salt
    dynamic_salt = lambda {|user| nil}
    encryptor = PluginAWeek::EncryptedAttributes::ShaEncryptor.new(@user, 'password', :write, :salt => dynamic_salt)
    assert_equal '', encryptor.salt
  end
  
  def test_should_append_salt_to_encrypted_value_if_dynamic
    encryptor = PluginAWeek::EncryptedAttributes::ShaEncryptor.new(@user, 'password', :write, :salt => :login)
    assert_equal 'a55d037f385cad22efe7862e07b805938d150154admin', encryptor.encrypt('secret')
  end
  
  def test_should_not_append_salt_to_encrypted_value_if_static
    encryptor = PluginAWeek::EncryptedAttributes::ShaEncryptor.new(@user, 'password', :write, :salt => 'custom_salt')
    assert_equal 'dc0fc7c07bba982a8d8f18fe138dbea912df5e0e', encryptor.encrypt('secret')
  end
end

class ShaEncryptorOnReadTest < Test::Unit::TestCase
  def setup
    @user = create_user(:login => 'admin')
    @encryptor = PluginAWeek::EncryptedAttributes::ShaEncryptor.new(@user, 'dc0fc7c07bba982a8d8f18fe138dbea912df5e0ecustom_salt', :read)
  end
  
  def test_should_should_use_remaining_characters_after_password_for_salt
    assert_equal 'custom_salt', @encryptor.salt
  end
  
  def test_should_be_able_to_perform_equality_on_encrypted_strings
    password = 'dc0fc7c07bba982a8d8f18fe138dbea912df5e0ecustom_salt'
    password.encryptor = @encryptor
    assert_equal 'secret', password
  end
end
