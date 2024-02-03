class AddProductProblemSpecificPeopleToBlueShifts < ActiveRecord::Migration
  def up
    add_column :blue_shifts, :product_problem_specific_people, :text
  end

  def down
    remove_column :blue_shifts, :product_problem_specific_people
  end
end
