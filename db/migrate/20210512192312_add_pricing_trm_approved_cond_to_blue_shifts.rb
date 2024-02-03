class AddPricingTrmApprovedCondToBlueShifts < ActiveRecord::Migration
  def change
    add_column :blue_shifts, :pricing_problem_approved_cond, :boolean, default: false
    add_column :blue_shifts, :pricing_problem_approved_cond_text, :text
  end
end
