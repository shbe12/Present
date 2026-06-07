class AddUniqueIndexToAttendances < ActiveRecord::Migration[8.1]
  def change
    add_index :attendances,
              [:member_id, :date],
              unique: true
  end
end
