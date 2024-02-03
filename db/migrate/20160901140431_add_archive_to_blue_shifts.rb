class AddArchiveToBlueShifts < ActiveRecord::Migration
  def up
    add_column :blue_shifts, :archived, :boolean, index: true
    add_column :blue_shifts, :archived_status, :string
    execute("UPDATE blue_shifts SET archived=false")
  end
  
  def down
    remove_column :blue_shifts, :archived
    remove_column :blue_shifts, :archived_status
  end
end
