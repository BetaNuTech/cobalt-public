class ChangeSalesAndGoalTypesForSalesForAgents < ActiveRecord::Migration
  def change
    change_column :sales_for_agents, :sales, :integer
    change_column :sales_for_agents, :goal, :integer
    change_column :sales_for_agents, :sales_prior_month, :integer
  end
end
