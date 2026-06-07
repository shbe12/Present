class CreateCharges < ActiveRecord::Migration[8.1]
  def change
    create_table :charges do |t|
      t.references :member, null: false, foreign_key: true
      t.references :attendance, null: true, foreign_key: true
      t.decimal :amount, precision: 8, scale: 2, null: false
      t.string :charge_type, null: false
      t.string :description
      t.date :due_date

      t.timestamps
    end
  end
end
