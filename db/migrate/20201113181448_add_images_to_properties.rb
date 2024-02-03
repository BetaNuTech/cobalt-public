class AddImagesToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :logo, :string
    add_column :properties, :image, :string
  end
end
