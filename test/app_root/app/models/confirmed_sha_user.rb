class ConfirmedShaUser < ShaUser
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