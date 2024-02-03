class AddLeasesNoMoniesToMetrics < ActiveRecord::Migration
  def change
        add_column :metrics, :leases_attained_no_monies, :decimal
  end
end
