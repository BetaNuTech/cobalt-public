class AddSalesPriorMonthToSalesForAgents < ActiveRecord::Migration
  def change
    add_column :sales_for_agents, :sales_prior_month, :decimal        
  end
end
