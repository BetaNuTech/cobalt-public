class AddTriggeredDataToBlueShifts < ActiveRecord::Migration

  def up
    change_table :blue_shifts do |t|
      t.decimal :basis_triggered_value
      t.decimal :trending_average_daily_triggered_value
      t.decimal :physical_occupancy_triggered_value
    end
  end

  def down
    remove_column :blue_shifts, :basis_triggered_value
    remove_column :blue_shifts, :trending_average_daily_triggered_value
    remove_column :blue_shifts, :physical_occupancy_triggered_value
  end
end
