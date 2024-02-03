class CreateCollectionsDetails < ActiveRecord::Migration
  def change
    create_table :collections_details do |t|
      t.references :property, index: true, foreign_key: true
      t.datetime :date_time, index: true
      t.decimal :num_of_units, index: true
      t.decimal :occupancy
      t.decimal :total_charges
      t.decimal :total_paid
      t.decimal :total_payment_plan
      t.decimal :total_evictions_owed
      t.decimal :num_of_unknown
      t.decimal :num_of_payment_plan
      t.decimal :num_of_paid_in_full
      t.decimal :num_of_evictions
  
      t.timestamps null: false
    end
  end
end
