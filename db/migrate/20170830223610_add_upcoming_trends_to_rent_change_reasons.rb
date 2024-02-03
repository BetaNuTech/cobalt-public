class AddUpcomingTrendsToRentChangeReasons < ActiveRecord::Migration
  def change
    add_column :rent_change_reasons, :average_daily_occupancy_trend_30days_out, :decimal
    add_column :rent_change_reasons, :average_daily_occupancy_trend_60days_out, :decimal
    add_column :rent_change_reasons, :average_daily_occupancy_trend_90days_out, :decimal
    add_column :rent_change_reasons, :last_survey_days_ago, :decimal
    add_column :rent_change_reasons, :num_of_units, :decimal
  end
end
