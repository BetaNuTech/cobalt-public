class AddAdot60ToCollectionsDetails < ActiveRecord::Migration
  def change
    add_column :collections_details, :avg_daily_occ_adj, :decimal
    add_column :collections_details, :avg_daily_trend_2mo_adj, :decimal
  end
end
