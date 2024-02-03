class AddEditArchiveToTrmBlueShifts < ActiveRecord::Migration
  def up
    add_reference :trm_blue_shifts, :archive_edit_user, references: :users, index: true
    add_foreign_key :trm_blue_shifts, :users, column: :archive_edit_user_id

    add_column :trm_blue_shifts, :initial_archived_status, :string
    add_column :trm_blue_shifts, :archive_edit_date, :date
  end

  def down
    remove_column :trm_blue_shifts, :archive_edit_user_id

    remove_column :trm_blue_shifts, :initial_archived_status
    remove_column :trm_blue_shifts, :archive_edit_date
  end
end
