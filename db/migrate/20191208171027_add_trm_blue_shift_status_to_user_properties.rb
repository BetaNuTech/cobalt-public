class AddTrmBlueShiftStatusToUserProperties < ActiveRecord::Migration
  def change
    add_column :user_properties, :trm_blue_shift_status, :string            
  end
end
