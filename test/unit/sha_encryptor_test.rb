require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))

class ShaEncryptorTest < Test::Unit::TestCase
  def test_process_options_exists
    assert PluginAWeek::EncryptedStrings::ShaEncryptor.respond_to?(:process_options)
  end
  
  def test_process_options_does_nothing_for_strings
    options = {:salt => 'my_salt_value'}
    expected_options = {:salt => 'my_salt_value'}
    PluginAWeek::EncryptedStrings::ShaEncryptor.process_options(User.new, :read, options)
    PluginAWeek::EncryptedStrings::ShaEncryptor.process_options(User.new, :write, options)
    
    assert_equal expected_options, options
  end
  
  def test_process_options_default_salt_on_read
    user = ShaUserWithSalt.new
    user.login = 'test'
    user.salt = 'existing_salt'
    
    options = {:salt => true}
    expected_options = {:salt => 'existing_salt'}
    PluginAWeek::EncryptedStrings::ShaEncryptor.process_options(user, :read, options)
    
    assert_equal expected_options, options
  end
  
  def test_process_options_default_salt_on_write
    user = ShaUserWithSalt.new
    user.login = 'test'
    user.salt = 'existing_salt'
    
    options = {:salt => true}
    expected_options = {:salt => 'test_salt'}
    PluginAWeek::EncryptedStrings::ShaEncryptor.process_options(user, :write, options)
    
    assert_equal expected_options, options
  end
  
  def test_process_options_custom_salt_on_read
    user = ShaUserWithCustomSalt.new
    user.login = 'test'
    user.salt_value = 'existing_salt_value'
    
    options = {:salt => :salt_value}
    expected_options = {:salt => 'existing_salt_value'}
    PluginAWeek::EncryptedStrings::ShaEncryptor.process_options(user, :read, options)
    
    assert_equal expected_options, options
  end
  
  def test_process_options_custom_salt_on_write
    user = ShaUserWithCustomSalt.new
    user.login = 'test'
    user.salt_value = 'existing_salt_value'
    
    options = {:salt => :salt_value}
    expected_options = {:salt => 'test_salt_value'}
    PluginAWeek::EncryptedStrings::ShaEncryptor.process_options(user, :write, options)
    
    assert_equal expected_options, options
  end
end
