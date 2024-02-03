class AddManagerToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :manager_slack_username, :string
    add_column :properties, :manager_strikes, :integer, default: 0, null: false
  end
end
