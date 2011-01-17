require File.dirname(__FILE__) + '/../test_helper'

class EncryptedAttributesTest < ActiveSupport::TestCase
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
  
  def test_should_encrypt_attribute_if_updating_with_same_password
    user = create_user(:login => 'admin', :password => 'secret')
    user.password = 'secret'
    user.save!
    user.reload
    assert user.password.encrypted?
    assert_not_equal String.new(user.password), 'secret'
    assert_equal '8152bc582f58c854f580cb101d3182813dec4afe', "#{user.password}"
  end
  
  def teardown
    User.class_eval do
      @before_validation_callbacks = nil
    end
  end
end

class EncryptedAttributesWithMultipleAttributesTest < ActiveSupport::TestCase
  def setup
    User.encrypts :password, :password_reminder
  end
  
  def test_should_both_using_sha
    user = create_user(:login => 'admin', :password => 'secret', :password_reminder => 'shhh')
    assert_equal '8152bc582f58c854f580cb101d3182813dec4afe', "#{user.password}"
    assert_equal '162cf5debf84cbc2af13da848544c3e2c515b4d3', "#{user.password_reminder}"
  end
  
  def test_should_encrypt_on_invalid_model
    user = new_user(:login => nil, :password => 'secret', :password_reminder => 'shhh')
    assert !user.valid?
    assert_equal '8152bc582f58c854f580cb101d3182813dec4afe', "#{user.password}"
    assert_equal '162cf5debf84cbc2af13da848544c3e2c515b4d3', "#{user.password_reminder}"
  end
  
  def test_should_not_encrypt_if_attributes_are_nil
    user = create_user(:login => 'admin', :password => nil, :password_reminder => nil)
    assert_nil user.password
    assert_nil user.password_reminder
  end
  
  def test_should_not_encrypt_if_attributes_are_blank
    user = create_user(:login => 'admin', :password => '', :password_reminder => '')
    assert_equal '', user.password
    assert_equal '', user.password_reminder
  end
  
  def test_should_not_encrypt_any_if_already_encrypted
    user = create_user(:login => 'admin', :password => 'secret'.encrypt, :password_reminder => 'shhh'.encrypt)
    assert_equal '8152bc582f58c854f580cb101d3182813dec4afe', "#{user.password}"
    assert_equal '162cf5debf84cbc2af13da848544c3e2c515b4d3', "#{user.password_reminder}"
  end
  
  def test_should_return_encrypted_attributes_for_saved_record
    user = create_user(:login => 'admin', :password => 'secret', :password_reminder => 'shhh')
    user = User.find(user.id)
    assert user.password.encrypted?
    assert_equal '8152bc582f58c854f580cb101d3182813dec4afe', "#{user.password}"
    
    assert user.password_reminder.encrypted?
    assert_equal '162cf5debf84cbc2af13da848544c3e2c515b4d3', "#{user.password_reminder}"
  end
  
  def test_should_not_encrypt_attributes_if_updating_without_any_changes
    user = create_user(:login => 'admin', :password => 'secret', :password_reminder => 'shhh')
    user.login = 'Administrator'
    user.save!
    assert user.password.encrypted?
    assert_equal '8152bc582f58c854f580cb101d3182813dec4afe', "#{user.password}"
    
    assert user.password_reminder.encrypted?
    assert_equal '162cf5debf84cbc2af13da848544c3e2c515b4d3', "#{user.password_reminder}"
  end
  
  def test_should_encrypt_attributes_if_updating_with_changes
    user = create_user(:login => 'admin', :password => 'secret', :password_reminder => 'shhh')
    user.password = 'shhh'
    user.password_reminder = 'secret'
    user.save!
    assert user.password.encrypted?
    assert_equal '162cf5debf84cbc2af13da848544c3e2c515b4d3', "#{user.password}"
    
    assert user.password_reminder.encrypted?
    assert_equal '8152bc582f58c854f580cb101d3182813dec4afe', "#{user.password_reminder}"
  end
  
  def teardown
    User.class_eval do
      @before_validation_callbacks = nil
    end
  end
end

class EncryptedAttributesWithDifferentTargetTest < ActiveSupport::TestCase
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

class EncryptedAttributesWithVirtualAttributeSourceTest < ActiveSupport::TestCase
  def setup
    User.encrypts :raw_password, :to => :crypted_password
  end
  
  def test_should_define_source_reader
    assert User.method_defined?(:raw_password)
  end
  
  def test_should_define_source_writer
    assert User.method_defined?(:raw_password=)
  end
  
  def test_should_encrypt_from_virtual_attribute
    user = create_user(:login => 'admin', :raw_password => 'secret')
    assert user.crypted_password.encrypted?
    assert_equal '8152bc582f58c854f580cb101d3182813dec4afe', "#{user.crypted_password}"
  end
  
  def teardown
    User.class_eval do
      @before_validation_callbacks = nil
      
      remove_method(:raw_password)
      remove_method(:raw_password=)
    end
  end
end

class EncryptedAttributesWithConflictingVirtualAttributeSourceTest < ActiveSupport::TestCase
  def setup
    User.class_eval do
      def raw_password
        'raw_password'
      end
      
      def raw_password=(value)
        self.password = value
      end
    end
    
    User.encrypts :raw_password, :to => :crypted_password
    @user = User.new
  end
  
  def test_should_not_define_source_reader
    assert_equal 'raw_password', @user.raw_password
  end
  
  def test_should_not_define_source_writer
    @user.raw_password = 'raw_password'
    assert_equal 'raw_password', @user.password
  end
  
  def teardown
    User.class_eval do
      @before_validation_callbacks = nil
      
      remove_method(:raw_password)
      remove_method(:raw_password=)
    end
  end
end

class EncryptedAttributesWithCustomCallbackTest < ActiveSupport::TestCase
  def setup
    User.encrypts :password, :on => :before_save
  end
  
  def test_should_not_encrypt_on_validation
    user = new_user(:login => 'admin', :password => 'secret')
    user.valid?
    assert_equal 'secret', user.password
  end
  
  def test_should_encrypt_on_create
    user = new_user(:login => 'admin', :password => 'secret')
    user.save
    assert_equal '8152bc582f58c854f580cb101d3182813dec4afe', "#{user.password}"
  end
  
  def teardown
    User.class_eval do
      @before_save_callbacks = nil
    end
  end
end

class EncryptedAttributesWithConditionalsTest < ActiveSupport::TestCase
  def test_should_not_encrypt_if_if_conditional_is_false
    User.encrypts :password, :if => lambda {|user| false}
    user = create_user(:login => 'admin', :password => 'secret')
    assert_equal 'secret', user.password
  end
  
  def test_should_encrypt_if_if_conditional_is_true
    User.encrypts :password, :if => lambda {|user| true}
    user = create_user(:login => 'admin', :password => 'secret')
    assert_equal '8152bc582f58c854f580cb101d3182813dec4afe', "#{user.password}"
  end
  
  def test_should_not_encrypt_if_unless_conditional_is_true
    User.encrypts :password, :unless => lambda {|user| true}
    user = create_user(:login => 'admin', :password => 'secret')
    assert_equal 'secret', user.password
  end
  
  def test_should_encrypt_if_unless_conditional_is_false
    User.encrypts :password, :unless => lambda {|user| false}
    user = create_user(:login => 'admin', :password => 'secret')
    assert_equal '8152bc582f58c854f580cb101d3182813dec4afe', "#{user.password}"
  end
  
  def teardown
    User.class_eval do
      @before_validation_callbacks = nil
    end
  end
end

class EncryptedAttributesWithBeforeCallbacksTest < ActiveSupport::TestCase
  def setup
    @password = nil
    @ran_callback = false
    User.encrypts :password, :before => lambda {|user| @ran_callback = true; @password = user.password.to_s}
    
    create_user(:login => 'admin', :password => 'secret')
  end
  
  def test_should_run_callback
    assert @ran_callback
  end
  
  def test_should_not_have_encrypted_yet
    assert_equal 'secret', @password
  end
  
  def teardown
    User.class_eval do
      @before_validation_callbacks = nil
      @before_encrypt_password_callbacks = nil
    end
  end
end

class EncryptedAttributesWithAfterCallbacksTest < ActiveSupport::TestCase
  def setup
    @password = nil
    @ran_callback = false
    User.encrypts :password, :after => lambda {|user| @ran_callback = true; @password = user.password.to_s}
    
    create_user(:login => 'admin', :password => 'secret')
  end
  
  def test_should_run_callback
    assert @ran_callback
  end
  
  def test_should_have_encrypted_already
    assert_equal '8152bc582f58c854f580cb101d3182813dec4afe', @password
  end
  
  def teardown
    User.class_eval do
      @before_validation_callbacks = nil
      @after_encrypt_password_callbacks = nil
    end
  end
end

class EncryptedAttributesWithDynamicConfigurationTest < ActiveSupport::TestCase
  def setup
    @salt = nil
    User.encrypts :password, :before => lambda {|user| user.salt = user.login} do |user|
      {:salt => @salt = user.salt}
    end
    
    @user = create_user(:login => 'admin', :password => 'secret')
  end
  
  def test_should_use_dynamic_configuration_during_write
    assert_equal 'a55d037f385cad22efe7862e07b805938d150154', "#{@user[:password]}"
  end
  
  def test_should_use_dynamic_configuration_during_read
    user = User.find(@user.id)
    assert_equal 'a55d037f385cad22efe7862e07b805938d150154', "#{user.password}"
  end
  
  def test_should_build_configuration_after_before_callbacks_invoked
    assert_equal 'admin', @salt
  end
  
  def teardown
    User.class_eval do
      @before_validation_callbacks = nil
      @before_encrypt_password_callbacks = nil
    end
  end
end

class ShaEncryptionTest < ActiveSupport::TestCase
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
  
  def test_should_use_sha_cipher
    assert_instance_of EncryptedAttributes::ShaCipher, @user.password.cipher
  end
  
  def test_should_use_default_salt
    assert_equal 'salt', @user.password.cipher.salt
  end
  
  def test_should_be_able_to_check_password
    assert_equal 'secret', @user. password
  end
  
  def teardown
    User.class_eval do
      @before_validation_callbacks = nil
    end
  end
end

class ShaWithEmbeddedSaltEncryptionTest < ActiveSupport::TestCase
  def setup
    User.encrypts :password, :mode => :sha, :salt => 'admin', :embed_salt => true
    @user = create_user(:login => 'admin', :password => 'secret')
  end
  
  def test_should_encrypt_password
    assert_equal 'a55d037f385cad22efe7862e07b805938d150154admin', "#{@user.password}"
  end
  
  def test_should_be_encrypted
    assert @user.password.encrypted?
  end
  
  def test_should_use_sha_cipher
    assert_instance_of EncryptedAttributes::ShaCipher, @user.password.cipher
  end
  
  def test_should_use_custom_salt
    assert_equal 'admin', @user.password.cipher.salt
  end
  
  def test_should_be_able_to_check_password
    assert_equal 'secret', @user.password
  end
  
  def test_should_be_dirty_when_attr_is_accessed_then_set_to_same_value
    # Access so that the cipher gets set, making equality work
    @user.password
    
    @user.password = 'secret'
    assert @user.password_changed?
  end
  
  def test_should_not_be_encrypted_if_changed_until_saved
    # Access so that the cipher gets set, making equality work
    @user.password
    
    @user.password = 'secret'
    3.times { assert !@user.password.encrypted? }
  end
  
  def teardown
    User.class_eval do
      @before_validation_callbacks = nil
    end
  end
end

class SymmetricEncryptionTest < ActiveSupport::TestCase
  def setup
    User.encrypts :password, :mode => :symmetric, :password => 'key'
    @user = create_user(:login => 'admin', :password => 'secret')
  end
  
  def test_should_encrypt_password
    assert_equal "zfKtnSa33tc=\n", @user.password
  end
  
  def test_should_be_encrypted
    assert @user.password.encrypted?
  end
  
  def test_should_use_sha_cipher
    assert_instance_of EncryptedStrings::SymmetricCipher, @user.password.cipher
  end
  
  def test_should_use_custom_password
    assert_equal 'key', @user.password.cipher.password
  end
  
  def test_should_be_able_to_check_password
    assert_equal 'secret', @user.password
  end
  
  def test_should_be_dirty_when_attr_is_accessed_then_set_to_same_value
    # Access so that the cipher gets set, making equality work
    @user.password
    
    @user.password = 'secret'
    assert @user.password_changed?
  end
  
  def test_should_not_be_encrypted_if_changed_until_saved
    # Access so that the cipher gets set, making equality work
    @user.password
    
    @user.password = 'secret'
    3.times { assert !@user.password.encrypted? }
  end
  
  def teardown
    User.class_eval do
      @before_validation_callbacks = nil
    end
  end
end

class AsymmetricEncryptionTest < ActiveSupport::TestCase
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
  
  def test_should_use_sha_cipher
    assert_instance_of EncryptedStrings::AsymmetricCipher, @user.password.cipher
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
