class CreateSalesForAgents < ActiveRecord::Migration
  def change
    create_table :sales_for_agents do |t|
      t.references :property, index: true, foreign_key: true
      t.date :date
      t.string :agent
      t.decimal :sales
      t.decimal :goal 
      
      t.timestamps null: false
    end
  end
end
