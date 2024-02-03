class AddLeasesLast24HrsAppliedToMetrics < ActiveRecord::Migration
  def change
    add_column :metrics, :leases_last_24hrs_applied, :boolean
  end
end
