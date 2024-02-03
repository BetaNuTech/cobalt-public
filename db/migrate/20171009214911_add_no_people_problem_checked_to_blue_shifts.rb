class AddNoPeopleProblemCheckedToBlueShifts < ActiveRecord::Migration
  def change
    add_column :blue_shifts, :no_people_problem_checked, :boolean        
  end
end
