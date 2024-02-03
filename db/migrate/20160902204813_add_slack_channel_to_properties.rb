class AddSlackChannelToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :slack_channel, :string
  end
end
