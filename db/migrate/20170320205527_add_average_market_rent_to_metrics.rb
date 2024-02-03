class AddAverageMarketRentToMetrics < ActiveRecord::Migration
  def change
    add_column :metrics, :average_market_rent, :decimal
  end
end
