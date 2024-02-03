class RemoveManagerUsernameFromProperties < ActiveRecord::Migration
  def change
      remove_column :properties, :manager_slack_username
  end
end
