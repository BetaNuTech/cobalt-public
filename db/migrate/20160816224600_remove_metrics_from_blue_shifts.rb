class RemoveMetricsFromBlueShifts < ActiveRecord::Migration
  def change
    remove_column :blue_shifts, :current_occupancy
    remove_column :blue_shifts, :current_trending
    remove_column :blue_shifts, :current_basis
  end
end
