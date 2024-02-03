class AddMoreReviewsToBlueShifts < ActiveRecord::Migration
  def change
    add_column :blue_shifts, :pricing_problem_denied, :boolean, default: false
    add_column :blue_shifts, :pricing_problem_approved, :boolean, default: false
  end
end
