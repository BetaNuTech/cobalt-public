class AddEmailsToSalesForAgents < ActiveRecord::Migration
  def change
    add_column :sales_for_agents, :agent_email, :string
  end
end
