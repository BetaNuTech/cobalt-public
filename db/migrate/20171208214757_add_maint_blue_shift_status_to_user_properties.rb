class AddMaintBlueShiftStatusToUserProperties < ActiveRecord::Migration
  def change
    add_column :user_properties, :maint_blue_shift_status, :string            
  end
end
