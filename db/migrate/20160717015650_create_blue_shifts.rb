class CreateBlueShifts < ActiveRecord::Migration
  def change
    create_table :blue_shifts do |t|
      t.references :property, index: true, foreign_key: true
      t.date :created_on
      t.decimal :current_occupancy
      t.decimal :current_trending
      t.decimal :current_basis
      t.boolean :people_problem
      t.text :people_problem_fix
      t.date :people_problem_fix_by
      t.boolean :product_problem
      t.text :product_problem_fix
      t.date :product_problem_fix_by
      t.boolean :pricing_problem
      t.text :pricing_problem_fix
      t.date :pricing_problem_fix_by
      t.boolean :need_help
      t.text :need_help_with
      t.timestamps null: false
    end
  end
end
