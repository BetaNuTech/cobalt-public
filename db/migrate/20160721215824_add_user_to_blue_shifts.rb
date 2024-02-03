class AddUserToBlueShifts < ActiveRecord::Migration
  def change
    add_reference :blue_shifts, :user, index: true, foreign_key: true
  end
end
