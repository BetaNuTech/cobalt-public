class AddSuperStarDataToSalesForAgents < ActiveRecord::Migration
  def change
    add_column :sales_for_agents, :super_star_goal, :integer
    add_column :sales_for_agents, :super_star_received, :boolean, :default => false
    add_column :sales_for_agents, :missed_goal, :boolean, :default => false
  end
end
