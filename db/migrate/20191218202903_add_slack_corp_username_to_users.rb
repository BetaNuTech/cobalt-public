class AddSlackCorpUsernameToUsers < ActiveRecord::Migration
  def change
    add_column :users, :slack_corp_username, :string
  end
end
