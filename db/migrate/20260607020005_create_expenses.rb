class CreateExpenses < ActiveRecord::Migration[8.1]
  def change
    create_table :expenses do |t|
      t.decimal :amount, precision: 8, scale: 2, null: false
      t.string :category, null: false
      t.string :description
      t.date :spent_on, null: false

      t.timestamps
    end
  end
end
