class RenamePhysicalOccupacyToPhysicalOccupancyInMetrics < ActiveRecord::Migration
  def change
    rename_column :metrics, :physical_occupacy, :physical_occupancy 
  end
end
