class CreatePropertyUnits < ActiveRecord::Migration
  def change
    create_table :property_units do |t|
      t.references :property, index: true, foreign_key: true
      t.boolean :model, index: true
      t.string :remoteid, index: true

      t.string :name
      t.integer :bedrooms
      t.integer :bathrooms
      t.integer :sqft
      t.string :occupancy
      t.string :lease_status
      t.date :vacate_on
      t.date :made_ready_on
      t.float :market_rent
      t.string :unit_type
      t.string :floorplan_name
      t.boolean :rent_ready

      t.integer :days_vacant
      t.integer :days_vacant_to_ready
      t.integer :days_ready_to_leased
      t.integer :days_ready_to_occupied
      t.integer :prev_days_vacant
      t.integer :prev_days_vacant_to_ready
      t.integer :prev_days_ready_to_leased
      t.integer :prev_days_ready_to_occupied

      t.datetime :data_start_datetime

      t.datetime :occupied_start_datetime
      t.datetime :occupied_end_datetime
      t.datetime :vacant_start_datetime
      t.datetime :vacant_end_datetime
      t.datetime :rent_ready_start_datetime
      t.datetime :rent_ready_end_datetime
      t.datetime :leased_start_datetime
      t.datetime :leased_end_datetime

      t.datetime :occupied_prev_start_datetime
      t.datetime :occupied_prev_end_datetime
      t.datetime :vacant_prev_start_datetime
      t.datetime :vacant_prev_end_datetime
      t.datetime :rent_ready_prev_start_datetime
      t.datetime :rent_ready_prev_end_datetime
      t.datetime :leased_prev_start_datetime
      t.datetime :leased_prev_end_datetime

      t.timestamps null: false
    end
  end
end
