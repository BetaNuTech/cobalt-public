class AddRollingSalesToMetrics < ActiveRecord::Migration
  def change
    add_column :metrics, :rolling_30_net_sales, :decimal
    add_column :metrics, :rolling_10_net_sales, :decimal
  end
end
