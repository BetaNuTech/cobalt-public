class AddAverageRentNewLeasesRenewalsByBedToMetrics < ActiveRecord::Migration
  def change
    add_column :metrics, :average_rent_1bed_net_effective, :decimal
    add_column :metrics, :average_rent_1bed_new_leases, :decimal
    add_column :metrics, :average_rent_1bed_renewal_leases, :decimal
    add_column :metrics, :average_rent_2bed_net_effective, :decimal
    add_column :metrics, :average_rent_2bed_new_leases, :decimal
    add_column :metrics, :average_rent_2bed_renewal_leases, :decimal
    add_column :metrics, :average_rent_3bed_net_effective, :decimal
    add_column :metrics, :average_rent_3bed_new_leases, :decimal
    add_column :metrics, :average_rent_3bed_renewal_leases, :decimal
    add_column :metrics, :average_rent_4bed_net_effective, :decimal
    add_column :metrics, :average_rent_4bed_new_leases, :decimal
    add_column :metrics, :average_rent_4bed_renewal_leases, :decimal
  end
end
