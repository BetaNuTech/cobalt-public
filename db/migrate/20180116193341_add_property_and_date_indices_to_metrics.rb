class AddPropertyAndDateIndicesToMetrics < ActiveRecord::Migration
  def change
    add_index :metrics, [:property_id, :date]    
  end
end
