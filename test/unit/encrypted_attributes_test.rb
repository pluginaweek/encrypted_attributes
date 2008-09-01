require File.dirname(__FILE__) + '/../test_helper'

class EncryptedAttributesTest < Test::Unit::TestCase
  def setup
    User.encrypts :password
  end
  
  def test_should_use_sha_by_default
    user = create_user(:login => 'admin', :password => 'secret')
    assert_equal '8152bc582f58c854f580cb101d3182813dec4afe', "#{user.password}"
  end
  
  def test_should_encrypt_on_invalid_model
    user = new_user(:login => nil, :password => 'secret')
    assert !user.valid?
    assert_equal '8152bc582f58c854f580cb101d3182813dec4afe', "#{user.password}"
  end
  
  def test_should_not_encrypt_if_attribute_is_nil
    user = create_user(:login => 'admin', :password => nil)
    assert_nil user.password
  end
  
  def test_should_not_encrypt_if_attribute_is_blank
    user = create_user(:login => 'admin', :password => '')
    assert_equal '', user.password
  end
  
  def test_should_not_encrypt_if_already_encrypted
    user = create_user(:login => 'admin', :password => 'secret'.encrypt)
    assert_equal '8152bc582f58c854f580cb101d3182813dec4afe', "#{user.password}"
  end
  
  def test_should_return_encrypted_attribute_for_saved_record
    user = create_user(:login => 'admin', :password => 'secret')
    user = User.find(user.id)
    assert user.password.encrypted?
    assert_equal '8152bc582f58c854f580cb101d3182813dec4afe', "#{user.password}"
  end
  
  def test_should_not_encrypt_attribute_if_updating_without_any_changes
    user = create_user(:login => 'admin', :password => 'secret')
    user.login = 'Administrator'
    user.save!
    assert user.password.encrypted?
    assert_equal '8152bc582f58c854f580cb101d3182813dec4afe', "#{user.password}"
  end
  
  def test_should_encrypt_attribute_if_updating_with_changes
    user = create_user(:login => 'admin', :password => 'secret')
    user.password = 'shhh'
    user.save!
    assert user.password.encrypted?
    assert_equal '162cf5debf84cbc2af13da848544c3e2c515b4d3', "#{user.password}"
  end
  
  def teardown
    User.class_eval do
      @before_validation_callbacks = nil
    end
  end
end

class EncryptedAttributesWithDifferentTargetTest < Test::Unit::TestCase
  def setup
    User.encrypts :password, :to => :crypted_password
  end
  
  def test_should_not_encrypt_if_attribute_is_nil
    user = create_user(:login => 'admin', :password => nil)
    assert_nil user.password
    assert_nil user.crypted_password
  end
  
  def test_should_not_encrypt_if_attribute_is_blank
    user = create_user(:login => 'admin', :password => '')
    assert_equal '', user.password
    assert_nil user.crypted_password
  end
  
  def test_should_not_encrypt_if_already_encrypted
    user = create_user(:login => 'admin', :crypted_password => 'secret'.encrypt)
    assert_equal '8152bc582f58c854f580cb101d3182813dec4afe', "#{user.crypted_password}"
  end
  
  def test_should_return_encrypted_attribute_for_saved_record
    user = create_user(:login => 'admin', :password => 'secret')
    user = User.find(user.id)
    assert user.crypted_password.encrypted?
    assert_equal '8152bc582f58c854f580cb101d3182813dec4afe', "#{user.crypted_password}"
  end
  
  def test_should_not_encrypt_attribute_if_updating_without_any_changes
    user = create_user(:login => 'admin', :password => 'secret')
    user.login = 'Administrator'
    user.save!
    assert user.crypted_password.encrypted?
    assert_equal '8152bc582f58c854f580cb101d3182813dec4afe', "#{user.crypted_password}"
  end
  
  def test_should_encrypt_attribute_if_updating_with_changes
    user = create_user(:login => 'admin', :password => 'secret')
    user.password = 'shhh'
    user.save!
    assert user.crypted_password.encrypted?
    assert_equal '162cf5debf84cbc2af13da848544c3e2c515b4d3', "#{user.crypted_password}"
  end
  
  def teardown
    User.class_eval do
      @before_validation_callbacks = nil
    end
  end
end

class EncryptedAttributesWithConditionalsTest < Test::Unit::TestCase
  def test_should_not_encrypt_if_if_conditional_is_false
    User.encrypts :password, :if => lambda {false}
    user = create_user(:login => 'admin', :password => 'secret')
    assert_equal 'secret', user.password
  end
  
  def test_should_encrypt_if_if_conditional_is_true
    User.encrypts :password, :if => lambda {true}
    user = create_user(:login => 'admin', :password => 'secret')
    assert_equal '8152bc582f58c854f580cb101d3182813dec4afe', "#{user.password}"
  end
  
  def test_should_not_encrypt_if_unless_conditional_is_true
    User.encrypts :password, :unless => lambda {true}
    user = create_user(:login => 'admin', :password => 'secret')
    assert_equal 'secret', user.password
  end
  
  def test_should_encrypt_if_unless_conditional_is_false
    User.encrypts :password, :unless => lambda {false}
    user = create_user(:login => 'admin', :password => 'secret')
    assert_equal '8152bc582f58c854f580cb101d3182813dec4afe', "#{user.password}"
  end
  
  def teardown
    User.class_eval do
      @before_validation_callbacks = nil
    end
  end
end

class ShaEncryptionTest < Test::Unit::TestCase
  def setup
    User.encrypts :password, :mode => :sha
    @user = create_user(:login => 'admin', :password => 'secret')
  end
  
  def test_should_encrypt_password
    assert_equal '8152bc582f58c854f580cb101d3182813dec4afe', "#{@user.password}"
  end
  
  def test_should_be_encrypted
    assert @user.password.encrypted?
  end
  
  def test_should_use_sha_encryptor
    assert_instance_of PluginAWeek::EncryptedAttributes::ShaEncryptor, @user.password.encryptor
  end
  
  def test_should_use_default_salt
    assert_equal 'salt', @user.password.encryptor.salt
  end
  
  def test_should_be_able_to_check_password
    assert_equal 'secret', @user.password
  end
  
  def teardown
    User.class_eval do
      @before_validation_callbacks = nil
    end
  end
end

class ShaWithCustomSaltEncryptionTest < Test::Unit::TestCase
  def setup
    User.encrypts :password, :mode => :sha, :salt => :login
    @user = create_user(:login => 'admin', :password => 'secret')
  end
  
  def test_should_encrypt_password
    assert_equal 'a55d037f385cad22efe7862e07b805938d150154admin', "#{@user.password}"
  end
  
  def test_should_be_encrypted
    assert @user.password.encrypted?
  end
  
  def test_should_use_sha_encryptor
    assert_instance_of PluginAWeek::EncryptedAttributes::ShaEncryptor, @user.password.encryptor
  end
  
  def test_should_use_custom_salt
    assert_equal 'admin', @user.password.encryptor.salt
  end
  
  def test_should_be_able_to_check_password
    assert_equal 'secret', @user.password
  end
  
  def teardown
    User.class_eval do
      @before_validation_callbacks = nil
    end
  end
end

class SymmetricEncryptionTest < Test::Unit::TestCase
  def setup
    User.encrypts :password, :mode => :symmetric, :key => 'key'
    @user = create_user(:login => 'admin', :password => 'secret')
  end
  
  def test_should_encrypt_password
    assert_equal "+YVKcPbqSWo=\n", @user.password
  end
  
  def test_should_be_encrypted
    assert @user.password.encrypted?
  end
  
  def test_should_use_sha_encryptor
    assert_instance_of PluginAWeek::EncryptedStrings::SymmetricEncryptor, @user.password.encryptor
  end
  
  def test_should_use_custom_key
    assert_equal 'key', @user.password.encryptor.key
  end
  
  def test_should_be_able_to_check_password
    assert_equal 'secret', @user.password
  end
  
  def teardown
    User.class_eval do
      @before_validation_callbacks = nil
    end
  end
end

class AsymmetricEncryptionTest < Test::Unit::TestCase
  def setup
    User.encrypts :password, :mode => :asymmetric,
      :private_key_file => File.dirname(__FILE__) + '/../keys/private',
      :public_key_file => File.dirname(__FILE__) + '/../keys/public'
    @user = create_user(:login => 'admin', :password => 'secret')
  end
  
  def test_should_encrypt_password
    assert_not_equal 'secret', "#{@user.password}"
    assert_equal 90, @user.password.length
  end
  
  def test_should_be_encrypted
    assert @user.password.encrypted?
  end
  
  def test_should_use_sha_encryptor
    assert_instance_of PluginAWeek::EncryptedStrings::AsymmetricEncryptor, @user.password.encryptor
  end
  
  def test_should_be_able_to_check_password
    assert_equal 'secret', @user.password
  end
  
  def teardown
    User.class_eval do
      @before_validation_callbacks = nil
    end
  end
end
