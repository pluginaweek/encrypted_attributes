class AsymmetricUser < User
  encrypts :password, :mode => :asymmetric
end