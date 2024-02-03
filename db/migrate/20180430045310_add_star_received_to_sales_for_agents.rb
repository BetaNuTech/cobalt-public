class AddStarReceivedToSalesForAgents < ActiveRecord::Migration
  def change
    add_column :sales_for_agents, :star_received, :boolean        
  end
end
