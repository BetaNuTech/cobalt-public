class CreateConversionsForAgents < ActiveRecord::Migration
  def change
    create_table :conversions_for_agents do |t|
      t.references :property, index: true, foreign_key: true
      t.date :date
      t.string :agent
      t.decimal :prospects_10days
      t.decimal :prospects_30days
      t.decimal :prospects_365days
      t.decimal :conversion_10days
      t.decimal :conversion_30days
      t.decimal :conversion_365days
      t.decimal :close_10days
      t.decimal :close_30days
      t.decimal :close_365days   
      t.decimal :decline_30days   
      
      t.timestamps null: false
    end
  end
end
