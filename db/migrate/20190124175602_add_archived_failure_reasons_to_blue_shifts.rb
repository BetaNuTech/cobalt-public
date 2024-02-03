class AddArchivedFailureReasonsToBlueShifts < ActiveRecord::Migration
  def up
    add_column :blue_shifts, :archived_failure_reasons, :string
  end

  def down
    remove_column :blue_shifts, :archived_failure_reasons
  end
end
