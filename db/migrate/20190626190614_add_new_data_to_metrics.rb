class AddNewDataToMetrics < ActiveRecord::Migration
  def change
    add_column :metrics, :average_days_vacant_over_seven, :decimal
    add_column :metrics, :denied_applications_current_month, :decimal
    add_column :metrics, :eviction_residents_over_two_months_due, :decimal
  end
end
