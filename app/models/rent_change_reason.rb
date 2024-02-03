# == Schema Information
#
# Table name: rent_change_reasons
#
#  id                                       :integer          not null, primary key
#  metric_id                                :integer
#  unit_type_code                           :string
#  old_market_rent                          :decimal(, )
#  percent_change                           :decimal(, )
#  change_amount                            :decimal(, )
#  trigger                                  :string
#  created_at                               :datetime         not null
#  updated_at                               :datetime         not null
#  new_rent                                 :decimal(, )
#  average_daily_occupancy_trend_30days_out :decimal(, )
#  average_daily_occupancy_trend_60days_out :decimal(, )
#  average_daily_occupancy_trend_90days_out :decimal(, )
#  last_survey_days_ago                     :decimal(, )
#  num_of_units                             :decimal(, )
#  property_id                              :integer
#  date                                     :date
#  units_vacant_not_leased                  :integer
#  units_on_notice_not_leased               :integer
#  last_three_rent                          :float
#
class RentChangeReason < ActiveRecord::Base
  belongs_to :metric, optional: true
  belongs_to :property
  # validates :metric, presence: true
  validates :property, presence: true
  validates :date, presence: true
  validates :unit_type_code, presence: true

  def change_level
    return 2 if change_amount > 0
    return 3 if change_amount < 0
    
    return nil
  end

  def trend_30days_out_level
    unless average_daily_occupancy_trend_30days_out.nil?
      return 1 if average_daily_occupancy_trend_30days_out >= 92
      return 2 if average_daily_occupancy_trend_30days_out >= 90
      return 3 if average_daily_occupancy_trend_30days_out >= 87
      return 6 if average_daily_occupancy_trend_30days_out < 87
    end
    return nil
  end

  def trend_60days_out_level
    unless average_daily_occupancy_trend_60days_out.nil?
      return 1 if average_daily_occupancy_trend_60days_out >= 92
      return 2 if average_daily_occupancy_trend_60days_out >= 90
      return 3 if average_daily_occupancy_trend_60days_out >= 87
      return 6 if average_daily_occupancy_trend_60days_out < 87
    end
    return nil
  end

  def trend_90days_out_level
    unless average_daily_occupancy_trend_90days_out.nil?
      return 1 if average_daily_occupancy_trend_90days_out >= 94
      return 2 if average_daily_occupancy_trend_90days_out >= 92
      return 3 if average_daily_occupancy_trend_90days_out >= 90
      return 6 if average_daily_occupancy_trend_90days_out < 90
    end
    return nil
  end

end
