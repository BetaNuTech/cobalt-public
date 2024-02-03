class AddNumOfLeadsNeededToConversionsForAgents < ActiveRecord::Migration
  def change
    add_column :conversions_for_agents, :num_of_leads_needed, :decimal
  end
end
