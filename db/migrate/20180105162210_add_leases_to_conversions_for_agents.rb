class AddLeasesToConversionsForAgents < ActiveRecord::Migration
  def change
    add_column :conversions_for_agents, :leases_30days, :decimal         
    add_column :conversions_for_agents, :leases_180days, :decimal         
    add_column :conversions_for_agents, :leases_365days, :decimal         
  end
end
