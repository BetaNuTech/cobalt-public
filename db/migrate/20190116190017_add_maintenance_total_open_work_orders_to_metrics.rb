class AddMaintenanceTotalOpenWorkOrdersToMetrics < ActiveRecord::Migration
  def change
    add_column :metrics, :maintenance_total_open_work_orders, :decimal
  end
end
