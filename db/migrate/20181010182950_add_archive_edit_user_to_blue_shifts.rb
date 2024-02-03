class AddArchiveEditUserToBlueShifts < ActiveRecord::Migration
  def up
    add_reference :blue_shifts, :archive_edit_user, references: :users, index: true
    add_foreign_key :blue_shifts, :users, column: :archive_edit_user_id

    add_reference :maint_blue_shifts, :archive_edit_user, references: :users, index: true
    add_foreign_key :maint_blue_shifts, :users, column: :archive_edit_user_id

    add_column :blue_shifts, :initial_archived_status, :string
    add_column :blue_shifts, :archive_edit_date, :date

    execute("UPDATE blue_shifts SET initial_archived_status = archived_status")
  end

  def down
    remove_column :blue_shifts, :archive_edit_user_id
    remove_column :maint_blue_shifts, :archive_edit_user_id

    remove_column :blue_shifts, :initial_archived_status
    remove_column :blue_shifts, :archive_edit_date
  end
end
