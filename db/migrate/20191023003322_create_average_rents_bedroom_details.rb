class CreateAverageRentsBedroomDetails < ActiveRecord::Migration
  def change
    create_table :average_rents_bedroom_details do |t|
      t.references :property, index: true, foreign_key: true
      t.date :date, index: true
      t.decimal :num_of_bedrooms, index: true
      t.decimal :net_effective_average_rent
      t.decimal :market_rent

      t.timestamps null: false
    end
  end
end
