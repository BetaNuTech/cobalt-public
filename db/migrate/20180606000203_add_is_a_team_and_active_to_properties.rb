class AddIsATeamAndActiveToProperties < ActiveRecord::Migration
  def up
    add_column :properties, :team_id, :integer
    add_column :properties, :active, :boolean        
    add_column :properties, :type, :string       
    
    execute("UPDATE properties SET type = 'Property'")
    execute("UPDATE properties SET active = true")
  end

  def down
    remove_column :properties, :team_id
    remove_column :properties, :active
    remove_column :properties, :type
  end

end
