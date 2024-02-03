class AddLastNoBlueShiftNeededDateToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :last_no_blue_shift_needed, :datetime
  end
end
