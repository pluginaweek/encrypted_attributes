require File.dirname(__FILE__) + '/../test_helper'

class ShaEncryptorTest < Test::Unit::TestCase
  def test_should_respond_to_process_options
    assert PluginAWeek::EncryptedStrings::ShaEncryptor.respond_to?(:process_options)
  end
  
  def test_process_options_should_not_make_changes_for_salt_string
    options = {:salt => 'my_salt_value'}
    expected_options = {:salt => 'my_salt_value'}
    PluginAWeek::EncryptedStrings::ShaEncryptor.process_options(User.new, :read, options)
    PluginAWeek::EncryptedStrings::ShaEncryptor.process_options(User.new, :write, options)
    
    assert_equal expected_options, options
  end
  
  def test_process_options_should_use_salt_attribute_for_salt_on_read
    user = ShaUserWithSalt.new
    user.login = 'test'
    user.salt = 'existing_salt'
    
    options = {:salt => true}
    expected_options = {:salt => 'existing_salt'}
    PluginAWeek::EncryptedStrings::ShaEncryptor.process_options(user, :read, options)
    
    assert_equal expected_options, options
  end
  
  def test_process_options_should_generate_new_salt_on_write
    user = ShaUserWithSalt.new
    user.login = 'test'
    user.salt = 'existing_salt'
    
    options = {:salt => true}
    expected_options = {:salt => 'test_salt'}
    PluginAWeek::EncryptedStrings::ShaEncryptor.process_options(user, :write, options)
    
    assert_equal expected_options, options
  end
  
  def test_process_options_should_use_custom_attribute_for_salt_on_read
    user = ShaUserWithCustomSalt.new
    user.login = 'test'
    user.salt_value = 'existing_salt_value'
    
    options = {:salt => :salt_value}
    expected_options = {:salt => 'existing_salt_value'}
    PluginAWeek::EncryptedStrings::ShaEncryptor.process_options(user, :read, options)
    
    assert_equal expected_options, options
  end
  
  def test_process_options_should_generate_new_salt_from_custom_method_on_write
    user = ShaUserWithCustomSalt.new
    user.login = 'test'
    user.salt_value = 'existing_salt_value'
    
    options = {:salt => :salt_value}
    expected_options = {:salt => 'test_salt_value'}
    PluginAWeek::EncryptedStrings::ShaEncryptor.process_options(user, :write, options)
    
    assert_equal expected_options, options
  end
end
