class AddInitialArchivedDateToBlueShifts < ActiveRecord::Migration
  def up
    add_column :maint_blue_shifts, :initial_archived_status, :string
    add_column :maint_blue_shifts, :archive_edit_date, :date

    add_column :blue_shifts, :initial_archived_date, :date
    add_column :maint_blue_shifts, :initial_archived_date, :date

    execute("UPDATE blue_shifts SET initial_archived_status = archived_status")
  end

  def down
    remove_column :maint_blue_shifts, :initial_archived_status
    remove_column :maint_blue_shifts, :archive_edit_date

    remove_column :blue_shifts, :initial_archived_date
    remove_column :maint_blue_shifts, :initial_archived_date
  end
end
