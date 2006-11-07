class User < ActiveRecord::Base
  validates_presence_of :login
  
  def create_salt
    "#{login}_salt"
  end
  
  def self.validates_password
    validates_presence_of :crypted_password
    validates_presence_of :password, :on => :create
    validates_length_of :password, :in => 4..40
  end
end

class ConfirmedUser < User
  validates_password
  validates_confirmation_of :password
end

class UnconfirmedUser < User
  validates_password
end