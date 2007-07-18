class ShaUserWithCustomSalt < User
  encrypts :password, :salt => :salt_value
  
  def create_salt_value
    "#{login}_salt_value"
  end
end