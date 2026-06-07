class CreateAttendances < ActiveRecord::Migration[8.1]
  def change
    create_table :attendances do |t|
      t.references :member, null: false, foreign_key: true
      t.date :date, null: false
      t.string :status, null: false
      t.text :notes

      t.timestamps
    end
  end
end
