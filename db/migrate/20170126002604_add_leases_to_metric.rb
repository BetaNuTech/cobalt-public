class AddLeasesToMetric < ActiveRecord::Migration
  def change
    add_column :metrics, :leases_attained, :decimal
    add_column :metrics, :leases_goal, :decimal
    add_column :metrics, :leases_alert_message, :string
  end
end
