class AddPeopleProblemDetailsToBlueShifts < ActiveRecord::Migration
  def up
    add_column :blue_shifts, :people_problem_reason_all_office_staff, :boolean, :default => false
    add_column :blue_shifts, :people_problem_reason_short_staffed, :boolean, :default => false
    add_column :blue_shifts, :people_problem_reason_specific_people, :boolean, :default => false
    add_column :blue_shifts, :people_problem_specific_people, :text
    add_column :blue_shifts, :people_problem_details, :text
  end

  def down
    remove_column :blue_shifts, :people_problem_reason_all_office_staff
    remove_column :blue_shifts, :people_problem_reason_short_staffed
    remove_column :blue_shifts, :people_problem_reason_specific_people
    remove_column :blue_shifts, :people_problem_specific_people
    remove_column :blue_shifts, :people_problem_details
  end
end
