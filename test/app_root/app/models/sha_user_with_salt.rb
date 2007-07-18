class ShaUserWithSalt < User
  encrypts :password, :salt => true
  
  def create_salt
    "#{login}_salt"
  end
end