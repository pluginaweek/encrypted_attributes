class User < ActiveRecord::Base
  validates_presence_of :login
end

class SHAUser < User
  encrypts :password
end

class ConfirmedSHAUser < SHAUser
  with_options(:if => :password_required?) do |klass|
    validates_presence_of     :password,
                              :crypted_password
    validates_length_of       :password,
                                :in => 4..40
    validates_confirmation_of :password
  end
  
  def password_required?
    crypted_password.blank? || !password.blank?
  end
end

class SHAUserWithSalt < User
  encrypts :password, :salt => true
  
  def create_salt
    "#{login}_salt"
  end
end

class SHAUserWithCustomCryptedAttr < User
  encrypts :password, :crypted_name => 'protected_password'
end

class AsymmetricUser < User
  encrypts :password, :mode => :asymmetrically
end

class SymmetricUser < User
  encrypts :password, :mode => :symmetrically
end