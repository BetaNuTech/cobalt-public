class Add180DayToConversionsForAgents < ActiveRecord::Migration
  def change
    add_column :conversions_for_agents, :prospects_180days, :decimal 
    add_column :conversions_for_agents, :conversion_180days, :decimal 
    add_column :conversions_for_agents, :close_180days, :decimal 
  end
end
