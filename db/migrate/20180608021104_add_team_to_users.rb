class AddTeamToUsers < ActiveRecord::Migration
  def up
    add_column :users, :team_id, :integer
  end

  def down
    remove_column :users, :team_id
  end
end
