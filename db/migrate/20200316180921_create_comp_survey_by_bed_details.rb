class CreateCompSurveyByBedDetails < ActiveRecord::Migration
  def change
    create_table :comp_survey_by_bed_details do |t|
      t.references :property, index: true, foreign_key: true
      t.date :date, index: true
      t.decimal :num_of_bedrooms, index: true
      t.decimal :our_market_rent
      t.decimal :comp_market_rent
      t.decimal :our_occupancy
      t.decimal :comp_occupancy
      t.decimal :days_since_last_survey
  
      t.timestamps null: false
    end
  end
end
