class AddFullNameToProperty < ActiveRecord::Migration
  def change
    add_column :properties, :full_name, :string
  end
end
