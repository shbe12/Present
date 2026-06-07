class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :member, null: false, foreign_key: true
      t.decimal :amount, precision: 8, scale: 2, null: false
      t.date :paid_on, null: false
      t.string :payment_method, null: false
      t.text :notes

      t.timestamps
    end
  end
end
