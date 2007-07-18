class SymmetricUser < User
  encrypts :password, :mode => :symmetric
end