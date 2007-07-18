require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))

class EncryptorTest < Test::Unit::TestCase
  def test_process_options
    assert PluginAWeek::EncryptedStrings::Encryptor.respond_to?(:process_options)
    
    options = {:salt => 'test'}
    expected_options = options.dup
    PluginAWeek::EncryptedStrings::Encryptor.process_options(User.new, :read, options)
    
    assert_equal expected_options, options
  end
end
