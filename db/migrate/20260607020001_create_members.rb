class CreateMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :members do |t|
      t.string :name, null: false
      t.string :phone
      t.string :email
      t.boolean :active, null: false, default: true
      t.date :joined_on

      t.timestamps
    end
  end
end
