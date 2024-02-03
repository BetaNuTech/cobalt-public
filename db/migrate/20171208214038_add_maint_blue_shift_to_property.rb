class AddMaintBlueShiftToProperty < ActiveRecord::Migration
  def up
    add_reference :properties, :current_maint_blue_shift, references: :maint_blue_shifts, index: true
    add_foreign_key :properties, :maint_blue_shifts, column: :current_maint_blue_shift_id

    add_column :properties, :maint_blue_shift_status, :string    
  end
  
  def down
    remove_column :properties, :current_blue_shift_id
    
    remove_column :properties, :maint_blue_shift_status    
  end
end
