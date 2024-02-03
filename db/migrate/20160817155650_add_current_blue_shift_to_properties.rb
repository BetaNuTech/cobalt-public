class AddCurrentBlueShiftToProperties < ActiveRecord::Migration
  def up
    add_reference :properties, :current_blue_shift, references: :blue_shifts, index: true
    add_foreign_key :properties, :blue_shifts, column: :current_blue_shift_id
    
    # execute("UPDATE properties \
    #  SET properties.current_blue_shift_id = blue_shifts.id = FROM properties \
    #  INNER JOIN blue_shifts ON blue_shifts.property_id = properties.id)")
    
    execute("UPDATE properties \
     SET current_blue_shift_id = (SELECT blue_shifts.id FROM
     blue_shifts WHERE blue_shifts.property_id = properties.id ORDER BY
     blue_shifts.created_at DESC LIMIT 1) WHERE properties.blue_shift_status = 'pending'")
  end
  
  def down
    remove_column :properties, :current_blue_shift_id
  end
end
