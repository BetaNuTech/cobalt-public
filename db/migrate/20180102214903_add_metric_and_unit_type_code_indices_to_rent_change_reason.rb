class AddMetricAndUnitTypeCodeIndicesToRentChangeReason < ActiveRecord::Migration
  def change
    add_index :rent_change_reasons, [:metric_id, :unit_type_code]    
  end
end
