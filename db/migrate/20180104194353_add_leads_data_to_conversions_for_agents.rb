class AddLeadsDataToConversionsForAgents < ActiveRecord::Migration
  def up
    add_column :conversions_for_agents, :is_property_data, :boolean     
    add_column :conversions_for_agents, :units, :integer     
    add_column :conversions_for_agents, :renewal_30days, :decimal     
    add_column :conversions_for_agents, :renewal_180days, :decimal     
    add_column :conversions_for_agents, :renewal_365days, :decimal     
    add_column :conversions_for_agents, :shows_30days, :decimal     
    add_column :conversions_for_agents, :shows_180days, :decimal     
    add_column :conversions_for_agents, :shows_365days, :decimal     
    add_column :conversions_for_agents, :submits_30days, :decimal     
    add_column :conversions_for_agents, :submits_180days, :decimal     
    add_column :conversions_for_agents, :submits_365days, :decimal     
    add_column :conversions_for_agents, :declines_30days, :decimal
    add_column :conversions_for_agents, :declines_180days, :decimal     
    add_column :conversions_for_agents, :declines_365days, :decimal     

    add_column :conversions_for_agents, :decline_180days, :decimal     
    add_column :conversions_for_agents, :decline_365days, :decimal     

    execute("UPDATE conversions_for_agents SET is_property_data=false")
  end

  def down
    remove_column :conversions_for_agents, :is_property_data     
    remove_column :conversions_for_agents, :units     
    remove_column :conversions_for_agents, :renewal_30days    
    remove_column :conversions_for_agents, :renewal_180days    
    remove_column :conversions_for_agents, :renewal_365days    
    remove_column :conversions_for_agents, :shows_30days  
    remove_column :conversions_for_agents, :shows_180days     
    remove_column :conversions_for_agents, :shows_365days   
    remove_column :conversions_for_agents, :submits_30days  
    remove_column :conversions_for_agents, :submits_180days    
    remove_column :conversions_for_agents, :submits_365days    
    remove_column :conversions_for_agents, :declines_30days
    remove_column :conversions_for_agents, :declines_180days     
    remove_column :conversions_for_agents, :declines_365days     

    remove_column :conversions_for_agents, :decline_180days   
    remove_column :conversions_for_agents, :decline_365days     
  end
end
