class CreateCollectionsByTenantDetails < ActiveRecord::Migration
  def change
    create_table :collections_by_tenant_details do |t|
      t.references :property, index: true, foreign_key: true
      t.datetime :date_time, index: true
      t.string :tenant_code, index: true
      t.string :tenant_name
      t.string :unit_code
      t.decimal :total_charges
      t.decimal :total_owed
      t.boolean :payment_plan
      t.boolean :eviction
    end
  end
end
