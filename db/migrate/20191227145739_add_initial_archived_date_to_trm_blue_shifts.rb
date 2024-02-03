class AddInitialArchivedDateToTrmBlueShifts < ActiveRecord::Migration
  def change
    add_column :trm_blue_shifts, :initial_archived_date, :date
  end
end
