require File.dirname(__FILE__) + '/../test_helper'

class EncryptorTest < Test::Unit::TestCase
  def test_should_not_make_any_changes_on_process_options
    assert PluginAWeek::EncryptedStrings::Encryptor.respond_to?(:process_options)
    
    options = {:salt => 'test'}
    expected_options = options.dup
    PluginAWeek::EncryptedStrings::Encryptor.process_options(User.new, :read, options)
    
    assert_equal expected_options, options
  end
end
