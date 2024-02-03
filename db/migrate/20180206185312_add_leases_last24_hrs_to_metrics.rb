class AddLeasesLast24HrsToMetrics < ActiveRecord::Migration
  def change
    add_column :metrics, :leases_last_24hrs, :decimal
  end
end
