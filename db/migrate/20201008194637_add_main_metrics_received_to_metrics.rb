class AddMainMetricsReceivedToMetrics < ActiveRecord::Migration
  def up
    add_column :metrics, :main_metrics_received, :boolean, :default => false

    execute("UPDATE metrics SET main_metrics_received=true")
  end

  def down
    remove_column :metrics, :main_metrics_received
  end

end
