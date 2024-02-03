class CreateCostarMarketData < ActiveRecord::Migration
  def change
    create_table :costar_market_data do |t|
      t.references :property, index: true, foreign_key: true
      t.date :date, index: true
      t.decimal :submarket_percent_vacant
      t.decimal :average_effective_rent
      t.decimal :studio_effective_rent
      t.decimal :one_bedroom_effective_rent
      t.decimal :two_bedroom_effective_rent
      t.decimal :three_bedroom_effective_rent
      t.decimal :four_bedroom_effective_rent

      t.timestamps null: false
    end
  end
end
