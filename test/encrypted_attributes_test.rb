require 'test/unit'

class EncryptedAttributesTest < Test::Unit::TestCase
  def test_should_encrypt_user_password
    u = ShaUser.new :login => 'bob'
    u.password = u.password_confirmation = 'test'
    assert u.save
    assert u.crypted_password = 'f438229716cab43569496f3a3630b3727524b81b'
  end
  
  def test_should_encrypt_user_password_without_confirmation
    u = DangerousUser.new :login => 'bob'
    u.password = 'test'
    assert u.save
    assert u.crypted_password = 'f438229716cab43569496f3a3630b3727524b81b'
  end
end
