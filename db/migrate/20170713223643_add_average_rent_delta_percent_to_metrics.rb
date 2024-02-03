class AddAverageRentDeltaPercentToMetrics < ActiveRecord::Migration
  def change
        add_column :metrics, :average_rent_delta_percent, :decimal
  end
end
