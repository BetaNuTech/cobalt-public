class AddCodeIndexToProperties < ActiveRecord::Migration
  def change
    add_index :properties, :code, :unique => true
  end
end
