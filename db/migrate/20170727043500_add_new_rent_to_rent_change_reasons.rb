class AddNewRentToRentChangeReasons < ActiveRecord::Migration
  def change
      add_column :rent_change_reasons, :new_rent, :decimal
  end
end
