class AddProductProblemResultsToBlueShifts < ActiveRecord::Migration
  def up
    add_column :blue_shifts, :people_problem_fix_results, :text
    add_column :blue_shifts, :product_problem_fix_results, :text
  end

  def down
    remove_column :blue_shifts, :people_problem_fix_results
    remove_column :blue_shifts, :product_problem_fix_results
  end
end
