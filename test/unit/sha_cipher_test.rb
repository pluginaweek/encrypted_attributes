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

class ShaCipherWithSaltEmbeddedAndCustomAlgorithmTest < Test::Unit::TestCase
  def test_should_support_md5
    cipher = EncryptedAttributes::ShaCipher.new('3b5ba11611dc1ba8bcdb0ff41aa693dcmd5_salt', :algorithm => 'md5', :embed_salt => true)
    assert_equal 'md5_salt', cipher.salt
  end
  
  def test_should_support_sha1
    cipher = EncryptedAttributes::ShaCipher.new('f8f70e06fed41c86c49766e6963ed4544647d638sha1_salt', :algorithm => 'sha1', :embed_salt => true)
    assert_equal 'sha1_salt', cipher.salt
  end
  
  def test_should_support_sha2
    cipher = EncryptedAttributes::ShaCipher.new('f2c5bd7ef9317004cca8680e7c12fa8a0b8ea9e7ebab8834ad9d818244d7c1d4sha2_salt', :algorithm => 'sha2', :embed_salt => true)
    assert_equal 'sha2_salt', cipher.salt
  end
  
  def test_should_support_sha256
    cipher = EncryptedAttributes::ShaCipher.new('1b75f1ebde621856c036118f296bae779548401566c982f2ec1efc089a587689sha256_salt', :algorithm => 'sha256', :embed_salt => true)
    assert_equal 'sha256_salt', cipher.salt
  end
  
  def test_should_support_sha384
    cipher = EncryptedAttributes::ShaCipher.new('d80570a23a1534d6a32201b01fa84b5d433a275f0aecd9cbdca2c726826e9034f90feb76fcdf49b9eafb21973962c75dsha384_salt', :algorithm => 'sha384', :embed_salt => true)
    assert_equal 'sha384_salt', cipher.salt
  end
  
  def test_should_support_sha512
    cipher = EncryptedAttributes::ShaCipher.new('44ffca1b3e63f0f1047f42656f43206d7d006c36d44f9f5ffde6c4679dc140f27ff4c8d310bbec902a9231a081e1c9d04236563331df29383e27037bb746df7fsha512_salt', :algorithm => 'sha512', :embed_salt => true)
    assert_equal 'sha512_salt', cipher.salt
  end
end
