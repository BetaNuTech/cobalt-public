class AddWorkableNameToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :workable_name, :string
  end
end
