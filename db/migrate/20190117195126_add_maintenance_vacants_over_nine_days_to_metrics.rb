class AddMaintenanceVacantsOverNineDaysToMetrics < ActiveRecord::Migration
  def change
    add_column :metrics, :maintenance_vacants_over_nine_days, :decimal
  end
end
