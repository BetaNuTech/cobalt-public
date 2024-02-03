class AddReviewedToBlueShifts < ActiveRecord::Migration
  def up
    add_column :blue_shifts, :reviewed, :boolean, default: false
    add_column :maint_blue_shifts, :reviewed, :boolean, default: false
  end

  def down
    remove_column :blue_shifts, :reviewed
    remove_column :maint_blue_shifts, :reviewed
  end
end
