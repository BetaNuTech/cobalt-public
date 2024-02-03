class CreateTrmBlueShifts < ActiveRecord::Migration
  def change
    create_table :trm_blue_shifts do |t|
      t.references :property, index: true, foreign_key: true
      t.references :metric, index: true, foreign_key: true  
      t.references :user, index: true, foreign_key: true    
      t.date :created_on
      t.boolean :manager_problem
      t.text :manager_problem_details
      t.text :manager_problem_fix
      t.text :manager_problem_results
      t.date :manager_problem_fix_by
      t.boolean :market_problem
      t.text :market_problem_details
      t.boolean :marketing_problem
      t.text :marketing_problem_details
      t.text :marketing_problem_fix
      t.date :marketing_problem_fix_by
      t.boolean :capital_problem
      t.text :capital_problem_details
      t.boolean :archived
      t.string :archived_status   
      t.timestamps null: false
    end
  end
end
