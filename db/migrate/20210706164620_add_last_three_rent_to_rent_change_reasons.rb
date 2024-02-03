class AddLastThreeRentToRentChangeReasons < ActiveRecord::Migration
  def change
    add_column :rent_change_reasons, :last_three_rent, :float
  end
end
