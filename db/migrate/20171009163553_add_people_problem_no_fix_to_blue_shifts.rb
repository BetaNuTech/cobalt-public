class AddPeopleProblemNoFixToBlueShifts < ActiveRecord::Migration
  def change
    add_column :blue_shifts, :no_people_problem_reason, :text    
  end
end
