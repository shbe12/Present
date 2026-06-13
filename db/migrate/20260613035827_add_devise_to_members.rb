class AddDeviseToMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :members, :encrypted_password, :string, null: false, default: ""
    add_column :members, :reset_password_token, :string
    add_column :members, :reset_password_sent_at, :datetime
    add_column :members, :remember_created_at, :datetime

    add_index :members, :reset_password_token, unique: true
  end
end
