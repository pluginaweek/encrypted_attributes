class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users, :force => true do |t|
      t.column :protected_password, :string, :limit => 255
      t.column :crypted_password,   :string, :limit => 255
      t.column :salt,               :string, :limit => 50
      t.column :salt_value,         :string, :limit => 50
      t.column :login,              :string, :limit => 50
      t.column :type,               :string, :limit => 20
    end
  end
  
  def self.down
    drop_table :users
  end
end