require File.dirname(__FILE__) + '/../test_helper'

class ShaCipherWithoutEmbeddingTest < Test::Unit::TestCase
  def setup
    @cipher = EncryptedAttributes::ShaCipher.new('dc0fc7c07bba982a8d8f18fe138dbea912df5e0e', :salt => 'custom_salt')
  end
  
  def test_should_use_configured_salt
    assert_equal 'custom_salt', @cipher.salt
  end
  
  def test_should_not_embed_salt_in_encrypted_string
    assert_equal 'dc0fc7c07bba982a8d8f18fe138dbea912df5e0e', @cipher.encrypt('secret')
  end
end

class ShaCipherWithNoSaltEmbeddedTest < Test::Unit::TestCase
  def setup
    @cipher = EncryptedAttributes::ShaCipher.new('dc0fc7c07bba982a8d8f18fe138dbea912df5e0e', :embed_salt => true, :salt => 'custom_salt')
  end
  
  def test_should_use_configured_salt
    assert_equal 'custom_salt', @cipher.salt
  end
  
  def test_should_embed_salt_in_encrypted_string
    assert_equal 'dc0fc7c07bba982a8d8f18fe138dbea912df5e0ecustom_salt', @cipher.encrypt('secret')
  end
end

class ShaCipherWithSaltEmbeddedTest < Test::Unit::TestCase
  def setup
    @cipher = EncryptedAttributes::ShaCipher.new('dc0fc7c07bba982a8d8f18fe138dbea912df5e0ecustom_salt', :embed_salt => true, :salt => 'ignored_salt')
  end
  
  def test_should_use_remaining_characters_after_password_for_salt
    assert_equal 'custom_salt', @cipher.salt
  end
  
  def test_should_embed_salt_in_encrypted_string
    assert_equal 'dc0fc7c07bba982a8d8f18fe138dbea912df5e0ecustom_salt', @cipher.encrypt('secret')
  end
end
