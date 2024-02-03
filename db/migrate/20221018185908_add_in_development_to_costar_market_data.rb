class AddInDevelopmentToCostarMarketData < ActiveRecord::Migration
  def change
    add_column :costar_market_data, :in_development, :boolean, :default => false
  end
end
