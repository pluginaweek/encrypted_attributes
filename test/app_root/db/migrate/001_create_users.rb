class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :login, :password, :crypted_password, :salt
    end
  end
  
  def self.down
    drop_table :users
  end
end
