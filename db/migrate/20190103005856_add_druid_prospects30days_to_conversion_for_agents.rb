class AddDruidProspects30daysToConversionForAgents < ActiveRecord::Migration
  def change
    add_column :conversions_for_agents, :druid_prospects_30days, :decimal
  end
end
