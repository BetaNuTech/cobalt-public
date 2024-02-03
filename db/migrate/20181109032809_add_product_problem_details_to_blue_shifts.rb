class AddProductProblemDetailsToBlueShifts < ActiveRecord::Migration
  def up
    add_column :blue_shifts, :product_problem_reason_curb_appeal, :boolean, :default => false
    add_column :blue_shifts, :product_problem_reason_unit_make_ready, :boolean, :default => false
    add_column :blue_shifts, :product_problem_reason_maintenance_staff, :boolean, :default => false
    add_column :blue_shifts, :product_problem_details, :text
  end

  def down
    remove_column :blue_shifts, :product_problem_reason_curb_appeal
    remove_column :blue_shifts, :product_problem_reason_unit_make_ready
    remove_column :blue_shifts, :product_problem_reason_maintenance_staff
    remove_column :blue_shifts, :product_problem_details
  end
end
