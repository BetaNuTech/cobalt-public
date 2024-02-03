class AddNumOfUnitsToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :num_of_units, :integer
  end
end
