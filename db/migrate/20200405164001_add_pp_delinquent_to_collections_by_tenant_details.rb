class AddPpDelinquentToCollectionsByTenantDetails < ActiveRecord::Migration
  def change
    add_column :collections_by_tenant_details, :payment_plan_delinquent, :boolean
  end
end
