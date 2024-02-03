class AddTrmBlueshiftToProperties < ActiveRecord::Migration
  def up
    add_reference :properties, :current_trm_blue_shift, references: :trm_blue_shifts, index: true
    add_foreign_key :properties, :trm_blue_shifts, column: :current_trm_blue_shift_id

    add_column :properties, :trm_blue_shift_status, :string    
  end
  
  def down
    remove_column :properties, :current_trm_blue_shift_id
    remove_column :properties, :trm_blue_shift_status    
  end
end
