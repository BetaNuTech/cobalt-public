class AddNewLeasesRenewalsToAverageRentsBedroomDetails < ActiveRecord::Migration
  def change
    add_column :average_rents_bedroom_details, :new_lease_average_rent, :decimal
    add_column :average_rents_bedroom_details, :renewal_lease_average_rent, :decimal
    add_column :average_rents_bedroom_details, :nom_of_new_leases, :decimal
    add_column :average_rents_bedroom_details, :num_of_renewal_leases, :decimal
  end
end
