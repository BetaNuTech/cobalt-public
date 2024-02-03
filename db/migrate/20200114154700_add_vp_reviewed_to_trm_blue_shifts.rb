class AddVpReviewedToTrmBlueShifts < ActiveRecord::Migration
  def change
    add_column :trm_blue_shifts, :vp_reviewed, :boolean
  end
end
