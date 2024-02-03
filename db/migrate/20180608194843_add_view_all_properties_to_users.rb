class AddViewAllPropertiesToUsers < ActiveRecord::Migration
  def change
    add_column :users, :view_all_properties, :boolean, default: false
  end
end
