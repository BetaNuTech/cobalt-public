class AddBlueShiftStatusToProperty < ActiveRecord::Migration
  def change
    add_column :properties, :blue_shift_status, :string
  end
end
