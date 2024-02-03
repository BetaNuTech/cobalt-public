class AddGoalForSlackToSalesForAgents < ActiveRecord::Migration
  def change
    add_column :sales_for_agents, :goal_for_slack, :integer
  end
end
