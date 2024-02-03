class AddAddendumReceivedToMetrics < ActiveRecord::Migration
  def change
    add_column :metrics, :addendum_received, :boolean, :default => false
  end
end
