class CreateRentChangeReasons < ActiveRecord::Migration
  def change
    create_table :rent_change_reasons do |t|
      t.references :metric, index: true, foreign_key: true
      t.string :unit_type_code
      t.decimal :old_market_rent
      t.decimal :percent_change
      t.decimal :change_amount
      t.string :trigger

      t.timestamps null: false
    end
  end
end
