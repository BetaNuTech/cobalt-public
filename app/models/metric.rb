# == Schema Information
#
# Table name: metrics
#
#  id                                                              :integer          not null, primary key
#  property_id                                                     :integer
#  position                                                        :integer
#  date                                                            :date
#  number_of_units                                                 :decimal(, )
#  physical_occupancy                                              :decimal(, )
#  cnoi                                                            :decimal(, )
#  trending_average_daily                                          :decimal(, )
#  trending_next_month                                             :decimal(, )
#  occupancy_average_daily                                         :decimal(, )
#  occupancy_budgeted_economic                                     :decimal(, )
#  occupancy_average_daily_30_days_ago                             :decimal(, )
#  average_rents_net_effective                                     :decimal(, )
#  average_rents_net_effective_budgeted                            :decimal(, )
#  basis                                                           :decimal(, )
#  basis_year_to_date                                              :decimal(, )
#  expenses_percentage_of_past_month                               :decimal(, )
#  expenses_percentage_of_budget                                   :decimal(, )
#  renewals_number_renewed                                         :decimal(, )
#  renewals_percentage_renewed                                     :decimal(, )
#  collections_current_status_residents_with_last_month_balance    :decimal(, )
#  collections_unwritten_off_balances                              :decimal(, )
#  collections_percentage_recurring_charges_collected              :decimal(, )
#  collections_current_status_residents_with_current_month_balance :decimal(, )
#  collections_number_of_eviction_residents                        :decimal(, )
#  maintenance_percentage_ready_over_vacant                        :decimal(, )
#  maintenance_number_not_ready                                    :decimal(, )
#  maintenance_turns_completed                                     :decimal(, )
#  maintenance_open_wos                                            :decimal(, )
#  created_at                                                      :datetime         not null
#  updated_at                                                      :datetime         not null
#  rolling_30_net_sales                                            :decimal(, )
#  rolling_10_net_sales                                            :decimal(, )
#  leases_attained                                                 :decimal(, )
#  leases_goal                                                     :decimal(, )
#  leases_alert_message                                            :string
#  leases_attained_no_monies                                       :decimal(, )
#  average_market_rent                                             :decimal(, )
#  average_rent_delta_percent                                      :decimal(, )
#  renewals_unknown                                                :decimal(, )
#  leases_last_24hrs                                               :decimal(, )
#  leases_last_24hrs_applied                                       :boolean
#  maintenance_total_open_work_orders                              :decimal(, )
#  maintenance_vacants_over_nine_days                              :decimal(, )
#  average_rent_weighted_per_unit_specials                         :decimal(, )
#  average_rent_year_over_year_without_vacancy                     :decimal(, )
#  average_rent_year_over_year_with_vacancy                        :decimal(, )
#  concessions_per_unit                                            :decimal(, )
#  concessions_budgeted_per_unit                                   :decimal(, )
#  average_days_vacant_over_seven                                  :decimal(, )
#  denied_applications_current_month                               :decimal(, )
#  collections_eviction_residents_over_two_months_due              :decimal(, )
#  renewals_residents_month_to_month                               :decimal(, )
#  budgeted_trended_occupancy                                      :decimal(, )
#  projected_cnoi                                                  :decimal(, )
#  renewals_ytd_percentage                                         :decimal(, )
#  average_rent_1bed_net_effective                                 :decimal(, )
#  average_rent_1bed_new_leases                                    :decimal(, )
#  average_rent_1bed_renewal_leases                                :decimal(, )
#  average_rent_2bed_net_effective                                 :decimal(, )
#  average_rent_2bed_new_leases                                    :decimal(, )
#  average_rent_2bed_renewal_leases                                :decimal(, )
#  average_rent_3bed_net_effective                                 :decimal(, )
#  average_rent_3bed_new_leases                                    :decimal(, )
#  average_rent_3bed_renewal_leases                                :decimal(, )
#  average_rent_4bed_net_effective                                 :decimal(, )
#  average_rent_4bed_new_leases                                    :decimal(, )
#  average_rent_4bed_renewal_leases                                :decimal(, )
#  addendum_received                                               :boolean          default(FALSE)
#  main_metrics_received                                           :boolean          default(FALSE)
#
class Metric < ActiveRecord::Base
  belongs_to :property
  has_many :rent_change_reasons
  validates :property, presence: true
  validates :date, presence: true
  validates :position, presence: true
  
  def physical_occupancy_level
    if !occupancy_budgeted_economic.nil? && occupancy_budgeted_economic > 0
      return get_metric_level(physical_occupancy, occupancy_budgeted_economic + 2, occupancy_budgeted_economic, occupancy_budgeted_economic - 2)
    end

    return get_metric_level(physical_occupancy, 95, 93, 91)
  end
  
  def cnoi_level
    return get_metric_level(cnoi, 101, 100, 99)
  end

  def cnoi_projected_level
    return get_metric_level(projected_cnoi, 101, 100, 99)
  end
  
  def trending_average_daily_level
    if !budgeted_trended_occupancy.nil? && budgeted_trended_occupancy > 0
      return get_metric_level(trending_average_daily, budgeted_trended_occupancy + 2, budgeted_trended_occupancy, budgeted_trended_occupancy - 2)
    end

    return get_metric_level(trending_average_daily, 94, 92, 90)
  end
  
  def trending_next_month_level
    return get_metric_level(trending_next_month, 92, 90, 88)
  end
  
  def occupancy_average_daily_level
    return 0 if occupancy_budgeted_economic.nil? || occupancy_average_daily.nil?
    if !occupancy_budgeted_economic.nil? && occupancy_budgeted_economic > 0
      return get_metric_level(occupancy_average_daily, occupancy_budgeted_economic + 2, occupancy_budgeted_economic, occupancy_budgeted_economic - 2)
    end
  end

  def average_market_rent_level
    if average_market_rent.nil? || average_market_rent == 0
      return 0
    end

    if average_rents_net_effective_budgeted.nil? || average_rents_net_effective_budgeted == 0
      return 0
    end

    diff = average_market_rent - average_rents_net_effective_budgeted
    percent_diff = (diff / average_rents_net_effective_budgeted) * 100.0

    return 2 if percent_diff < 0 && percent_diff >= -2
    return 3 if percent_diff < -2 && percent_diff >= -5
    return 6 if percent_diff < -5

    return 0
  end
  
  def average_rents_net_effective_level
    if average_rents_net_effective_budgeted.nil? || average_rents_net_effective_budgeted == 0
      return 0
    end

    return 0 if average_rents_net_effective.nil?

    return 1 if (average_rents_net_effective - average_rents_net_effective_budgeted) / average_rents_net_effective_budgeted > 0.02
    return 2 if average_rents_net_effective  >= average_rents_net_effective_budgeted
    return 3 if (average_rents_net_effective_budgeted - average_rents_net_effective) / average_rents_net_effective_budgeted <= 0.02
    return 6 if (average_rents_net_effective_budgeted - average_rents_net_effective) / average_rents_net_effective_budgeted > 0.02
    
    return 0
  end

  # Concession Severity Scale: (From Monica, 9/16/19)
  # Blue – Exceeding Budget
  # Green – At Budget
  # Red – $1 to $9 per unit > budgeted per unit concession
  # Bold Red Highlight - $10 and above per unit > budgeted per unit concession

  def concessions_level
    # No value for concessions
    return 0 if concessions_per_unit.nil?

    if concessions_budgeted_per_unit.nil? || concessions_budgeted_per_unit == 0
      # zero budget
      delta = concessions_per_unit
    else
      # non-zero budget
      delta = concessions_per_unit - concessions_budgeted_per_unit
    end

    # Blue
    return 1 if delta < 0
    # Green
    return 2 if delta == 0
    # Red
    return 3 if delta <= 9
    # White/Red
    return 6
  end

  # def concessions_level
  #   # No value for concessions
  #   return nil if concessions_per_unit.nil?

  #   if concessions_budgeted_per_unit.nil? || concessions_budgeted_per_unit == 0
  #     # zero budget
  #     delta = concessions_per_unit
  #     budget = 0
  #   else
  #     # non-zero budget
  #     delta = concessions_per_unit - concessions_budgeted_per_unit
  #     budget = concessions_budgeted_per_unit
  #   end

  #   # If zero or negative budget
  #   if budget <= 0
  #     return 4 if delta >= 1 and delta <= 5
  #     return 5 if delta >= 6 and delta <= 10
  #     return 6 if delta >= 11    
  #     return 1
  #   end

  #   # If positive budget
  #   percent_of_budget = (concessions_per_unit / budget) * 100.0
  #   return 1 if percent_of_budget <= 90
  #   return 2 if percent_of_budget > 90 and percent_of_budget <= 105
  #   return 3 if percent_of_budget > 105 and percent_of_budget <= 120
  #   return 3 if percent_of_budget > 120 and delta == 1
  #   return 4 if percent_of_budget > 120 and percent_of_budget <= 250
  #   return 5 if percent_of_budget > 250 and percent_of_budget <= 500
  #   return 6 if percent_of_budget > 500
    
  #   return 0
  # end
  
  def basis_level
    return 0 if basis.nil?
    return 1 if basis > Metric.blue_shift_threshold_for_basis
    return 2 if basis == Metric.blue_shift_threshold_for_basis
    return 3 if basis >= 99 and basis < Metric.blue_shift_threshold_for_basis
    return 6 if basis < 99 
    
    return 0
  end

  def basis_year_to_date_level
    return 0 if basis_year_to_date.nil?
    return 1 if basis_year_to_date > 100
    return 2 if basis_year_to_date == 100
    return 3 if basis_year_to_date >= 99 and basis_year_to_date < 100
    return 6 if basis_year_to_date < 99 
    
    return 0
  end
  
  def expenses_percentage_of_budget_level
    return 0 if expenses_percentage_of_budget.nil?
    return 1 if expenses_percentage_of_budget >= 0 and expenses_percentage_of_budget <= 100
    return 2 if expenses_percentage_of_budget > 100 and expenses_percentage_of_budget <= 101
    return 3 if expenses_percentage_of_budget > 101 and expenses_percentage_of_budget <= 103
    return 6 if expenses_percentage_of_budget > 103
    
    return 0
  end

  def expenses_percentage_of_past_month_level
    if date < Date.new(2016,9,13) # Entries changed meaning at this date
      return 0 if expenses_percentage_of_past_month.nil? || expenses_percentage_of_budget.nil?
      return 1 if expenses_percentage_of_past_month.zero? # Avoid divide by zero
      percentage_difference = (expenses_percentage_of_past_month - expenses_percentage_of_budget) / expenses_percentage_of_past_month 
      return 1 if percentage_difference > 0.05
      return 2 if percentage_difference <= 0.05 and percentage_difference >= -0.05
      return 3 if percentage_difference < -0.05 and percentage_difference >= -0.10 
      return 6 if percentage_difference < -0.10 
    else
      # expenses_percentage_of_past_month means percentage of budget here
      return 0 if expenses_percentage_of_past_month.nil?
      percent_of_month = (date.mday.to_f / Date.new(date.year,date.mon,-1).mday.to_f) * 100.0
      percentage_difference = (percent_of_month - expenses_percentage_of_past_month) / percent_of_month 
      return 1 if percentage_difference > 0.05
      return 2 if percentage_difference <= 0.05 and percentage_difference >= -0.05
      return 3 if percentage_difference < -0.05 and percentage_difference >= -0.10 
      return 6 if percentage_difference < -0.10 
    end
    
    return 0
  end

  def renewals_unknowns_level
    return 0 if renewals_unknown.nil?
    return 1 if renewals_unknown == 0
    return 2 if renewals_unknown >= 1 and renewals_unknown < 3
    return 3 if renewals_unknown >= 3 and renewals_unknown <= 5
    return 6 if renewals_unknown > 5
    
    return 0
  end
  
  def renewals_percentage_renewed_level
    return 0 if renewals_percentage_renewed.nil?
    return 1 if renewals_percentage_renewed > 50
    return 2 if renewals_percentage_renewed >= 45 and renewals_percentage_renewed <= 50
    return 3 if renewals_percentage_renewed >= 40 and renewals_percentage_renewed < 45
    return 6 if renewals_percentage_renewed < 40
    
    return 0
  end
  
  def collections_current_status_residents_with_last_month_balance_level
    return 0 if collections_current_status_residents_with_last_month_balance.nil?
    return 1 if collections_current_status_residents_with_last_month_balance == 0
    return 2 if collections_current_status_residents_with_last_month_balance == 1
    return 3 if collections_current_status_residents_with_last_month_balance == 2
    return 6 if collections_current_status_residents_with_last_month_balance > 2
    return 0
  end
  
  def collections_unwritten_off_balances_level
    return get_metric_level_using_percentage_of_units(collections_unwritten_off_balances)
  end
  
  def collections_percentage_recurring_charges_collected_level
    return 0 if collections_percentage_recurring_charges_collected.nil?
    if date.day >= 1 and date.day <= 5
      return 1 if collections_percentage_recurring_charges_collected > 99
      return 2 if collections_percentage_recurring_charges_collected > 98
      return 3 if collections_percentage_recurring_charges_collected >= 95 and collections_percentage_recurring_charges_collected <= 98
      return 6 if collections_percentage_recurring_charges_collected < 95
    else
      return 1 if collections_percentage_recurring_charges_collected == 100
      return 2 if collections_percentage_recurring_charges_collected >= 99
      return 3 if collections_percentage_recurring_charges_collected >= 98 and collections_percentage_recurring_charges_collected < 99
      return 6 if collections_percentage_recurring_charges_collected < 98      
    end  
  end
  
  def collections_current_status_residents_with_current_month_balance_level
    return get_metric_level_using_percentage_of_units(collections_current_status_residents_with_current_month_balance)
  end
  
  def collections_number_of_eviction_residents_level
    return get_metric_level_using_percentage_of_units(collections_number_of_eviction_residents)
  end

  def collections_eviction_residents_over_two_months_due_level
    return get_metric_level_using_percentage_of_units(collections_eviction_residents_over_two_months_due)
  end
  
  def maintenance_percentage_ready_over_vacant_level
    return 0 if maintenance_percentage_ready_over_vacant.nil?
    return 1 if maintenance_percentage_ready_over_vacant > 99
    return 2 if maintenance_percentage_ready_over_vacant > 95 && maintenance_percentage_ready_over_vacant <= 99
    return 3 if maintenance_percentage_ready_over_vacant >= 90 && maintenance_percentage_ready_over_vacant <= 95
    return 6 if maintenance_percentage_ready_over_vacant < 90
    return 0    
  end
  
  def maintenance_number_not_ready_level
    return 0 if maintenance_number_not_ready.nil?
    return 1 if maintenance_number_not_ready == 0
    return 2 if maintenance_number_not_ready > 0 && maintenance_number_not_ready / number_of_units <= 0.02
    return 3 if maintenance_number_not_ready > 0 && maintenance_number_not_ready / number_of_units > 0.02 && maintenance_number_not_ready / number_of_units <= 0.04
    return 6 if maintenance_number_not_ready > 0 && maintenance_number_not_ready / number_of_units > 0.04
  end
  
  def maintenance_open_wos_level
    return 0 if maintenance_open_wos.nil?
    return 1 if maintenance_open_wos == 0
    return 2 if maintenance_open_wos >  0 && maintenance_open_wos / number_of_units <  0.02 && maintenance_open_wos <= 10
    return 3 if maintenance_open_wos >  0 && maintenance_open_wos / number_of_units <  0.04 && maintenance_open_wos <= 20
    return 6 if maintenance_open_wos > 20 || maintenance_open_wos / number_of_units >= 0.04
    
    return 0
  end

  # TRM - Per Property Triggers: 1 and 2 or 1 and 3 or 2 and 3 or 1, 2 or 3 and 4 or 1,2 or 3 and 5
    #   1.)	Occupancy - 1.5% below Budgeted Occupancy
    #   2.)	30 day Trend – 3.5% below Budgeted Occupancy 
    #   3.)	60 day Trend – 5% below Budgeted Occupancy 
    #   4.)	1 lease or less in 10 days (rolling, or start checking on 10th day?)
    #   5.)	Less that 5 leases in rolling 30 days

  def self.trm_blueshift_form_needed?(metrics)
    if Metric.avg_and_latest_trm_occupancy_level_triggered?(metrics) && Metric.avg_and_latest_trm_30d_trend_level_triggered?(metrics)
      return true
    end
    if Metric.avg_and_latest_trm_occupancy_level_triggered?(metrics) && Metric.avg_and_latest_trm_60d_trend_level_triggered?(metrics)
      return true
    end
    if Metric.avg_and_latest_trm_30d_trend_level_triggered?(metrics) && Metric.avg_and_latest_trm_60d_trend_level_triggered?(metrics)
      return true
    end
    if (Metric.avg_and_latest_trm_occupancy_level_triggered?(metrics) || Metric.avg_and_latest_trm_30d_trend_level_triggered?(metrics) || Metric.avg_and_latest_trm_60d_trend_level_triggered?(metrics)) && Metric.avg_and_latest_trm_10d_leases_level_triggered?(metrics)
      return true
    end
    if (Metric.avg_and_latest_trm_occupancy_level_triggered?(metrics) || Metric.avg_and_latest_trm_30d_trend_level_triggered?(metrics) || Metric.avg_and_latest_trm_60d_trend_level_triggered?(metrics)) && Metric.avg_and_latest_trm_30d_leases_level_triggered?(metrics)
      return true
    end

    return false
  end

  def trm_blueshift_trigger_reasons
    metrics = [self]

    trigger_metrics = []

    if Metric.avg_and_latest_trm_occupancy_level_triggered?(metrics) && Metric.avg_and_latest_trm_30d_trend_level_triggered?(metrics)
      trigger_metrics << "Occupancy(#{metrics.last.physical_occupancy}%) 1.5% < Budget(#{metrics.last.occupancy_budgeted_economic}%) AND 30d Trending(#{metrics.last.trending_next_month}%) 3.5% < Budget(#{metrics.last.occupancy_budgeted_economic}%)"
    end
    if Metric.avg_and_latest_trm_occupancy_level_triggered?(metrics) && Metric.avg_and_latest_trm_60d_trend_level_triggered?(metrics)
      trigger_metrics << "Occupancy(#{metrics.last.physical_occupancy}%) 1.5% < Budget(#{metrics.last.occupancy_budgeted_economic}%) AND 60d Trending(#{metrics.last.trending_average_daily}%) 5% < Budget(#{metrics.last.occupancy_budgeted_economic}%)"
    end
    if Metric.avg_and_latest_trm_30d_trend_level_triggered?(metrics) && Metric.avg_and_latest_trm_60d_trend_level_triggered?(metrics)
      trigger_metrics << "30d Trending(#{metrics.last.trending_next_month}%) 3.5% < Budget(#{metrics.last.occupancy_budgeted_economic}%) AND 60d Trending(#{metrics.last.trending_average_daily}%) 5% < Budget(#{metrics.last.occupancy_budgeted_economic}%)"
    end
    if (Metric.avg_and_latest_trm_occupancy_level_triggered?(metrics) || Metric.avg_and_latest_trm_30d_trend_level_triggered?(metrics) || Metric.avg_and_latest_trm_60d_trend_level_triggered?(metrics)) && Metric.avg_and_latest_trm_10d_leases_level_triggered?(metrics)
      or_values = ""
      if Metric.avg_and_latest_trm_occupancy_level_triggered?(metrics)
        or_values = "Occupancy(#{metrics.last.physical_occupancy}%) 1.5% < Budget(#{metrics.last.occupancy_budgeted_economic}%)"
      end
      if Metric.avg_and_latest_trm_30d_trend_level_triggered?(metrics)
        if or_values.length > 0
          or_values += ", "
        end
        or_values += "30d Trending(#{metrics.last.trending_next_month}%) 3.5% < Budget(#{metrics.last.occupancy_budgeted_economic}%)"
      end
      if Metric.avg_and_latest_trm_60d_trend_level_triggered?(metrics)
        if or_values.length > 0
          or_values += ", "
        end
        or_values += "60d Trending(#{metrics.last.trending_average_daily}%) 5% < Budget(#{metrics.last.occupancy_budgeted_economic}%)"
      end
      trigger_metrics << "(#{or_values}) AND Rolling 10d Net Sales(#{rolling_10_net_sales}) < 2"
    end
    if (Metric.avg_and_latest_trm_occupancy_level_triggered?(metrics) || Metric.avg_and_latest_trm_30d_trend_level_triggered?(metrics) || Metric.avg_and_latest_trm_60d_trend_level_triggered?(metrics)) && Metric.avg_and_latest_trm_30d_leases_level_triggered?(metrics)
      or_values = ""
      if Metric.avg_and_latest_trm_occupancy_level_triggered?(metrics)
        or_values = "Occupancy(#{metrics.last.physical_occupancy}%) 1.5% < Budget(#{metrics.last.occupancy_budgeted_economic}%)"
      end
      if Metric.avg_and_latest_trm_30d_trend_level_triggered?(metrics)
        if or_values.length > 0
          or_values += ", "
        end
        or_values += "30d Trending(#{metrics.last.trending_next_month}%) 3.5% < Budget(#{metrics.last.occupancy_budgeted_economic}%)"
      end
      if Metric.avg_and_latest_trm_60d_trend_level_triggered?(metrics)
        if or_values.length > 0
          or_values += ", "
        end
        or_values += "60d Trending(#{metrics.last.trending_average_daily}%) 5% < Budget(#{metrics.last.occupancy_budgeted_economic}%)"
      end
      trigger_metrics << "(#{or_values}) AND Rolling 30d Net Sales(#{metrics.last.rolling_30_net_sales}) < 5"
    end

    return trigger_metrics
  end

  def self.avg_and_latest_trm_occupancy_level_triggered?(metrics)
    if metrics.last == nil
      return false
    end

    budget_offset = 1.5

    if !metrics.last.occupancy_budgeted_economic.nil? && metrics.last.occupancy_budgeted_economic > 0
      average_value = Metric.average_physical_occupancy(metrics) < (metrics.last.occupancy_budgeted_economic - budget_offset)
      latest_value = metrics.last.physical_occupancy < (metrics.last.occupancy_budgeted_economic - budget_offset)
      return average_value && latest_value
    end
    return false
  end

  def self.avg_and_latest_trm_30d_trend_level_triggered?(metrics)
    if metrics.last == nil
      return false
    end

    budget_offset = 3.5

    if !metrics.last.occupancy_budgeted_economic.nil? && metrics.last.occupancy_budgeted_economic > 0
      average_value = Metric.average_trending_next_month(metrics) < (metrics.last.occupancy_budgeted_economic - budget_offset)
      latest_value = metrics.last.trending_next_month < (metrics.last.occupancy_budgeted_economic - budget_offset)
      return average_value && latest_value
    end
    return false
  end

  def self.avg_and_latest_trm_60d_trend_level_triggered?(metrics)
    if metrics.last == nil
      return false
    end

    budget_offset = 5

    if !metrics.last.occupancy_budgeted_economic.nil? && metrics.last.occupancy_budgeted_economic > 0
      average_value = Metric.average_trending_average_daily(metrics) < (metrics.last.occupancy_budgeted_economic - budget_offset)
      latest_value = metrics.last.trending_average_daily < (metrics.last.occupancy_budgeted_economic - budget_offset)
      return average_value && latest_value
    end
    return false
  end

  def self.avg_and_latest_trm_10d_leases_level_triggered?(metrics)
    if metrics.last == nil
      return false
    end

    threshold = 2

    average_value = Metric.average_rolling_10_net_sales(metrics) < threshold
    latest_value = metrics.last.rolling_10_net_sales < threshold
    return average_value && latest_value
  end

  def self.avg_and_latest_trm_30d_leases_level_triggered?(metrics)
    if metrics.last == nil
      return false
    end

    threshold = 5

    average_value = Metric.average_rolling_30_net_sales(metrics) < threshold
    latest_value = metrics.last.rolling_30_net_sales < threshold
    return average_value && latest_value
  end
  
  def self.blue_shift_threshold_for_physical_occupancy(metric)
    if !metric.occupancy_budgeted_economic.nil? && metric.occupancy_budgeted_economic > 0
      return metric.occupancy_budgeted_economic
    end

    return 93
  end

  def self.blue_shift_threshold_for_trending_average_daily(metric)
    if !metric.budgeted_trended_occupancy.nil? && metric.budgeted_trended_occupancy > 0
      return metric.budgeted_trended_occupancy - 3
    end

    return 92
  end

  def self.blue_shift_threshold_for_basis
    return 100
  end

  def self.blue_shift_success_value_for_physical_occupancy(blue_shift, metric)
    if blue_shift.physical_occupancy_triggered_value == nil
      return Metric.blue_shift_threshold_for_physical_occupancy(metric)
    end

    success_value = blue_shift.physical_occupancy_triggered_value + 1
    if success_value > Metric.blue_shift_threshold_for_physical_occupancy(metric)
      return Metric.blue_shift_threshold_for_physical_occupancy(metric)
    end
    
    return success_value
  end

  def self.blue_shift_success_value_for_trending_average_daily(blue_shift, metric)
    if blue_shift.trending_average_daily_triggered_value == nil
      return Metric.blue_shift_threshold_for_trending_average_daily(metric)
    end
    
    success_value = blue_shift.trending_average_daily_triggered_value + 1
    if success_value > Metric.blue_shift_threshold_for_trending_average_daily(metric)
      return Metric.blue_shift_threshold_for_trending_average_daily(metric)
    end
    
    return success_value
  end

  def self.blue_shift_success_value_for_basis(blue_shift)
    if blue_shift.basis_triggered_value == nil
      return Metric.blue_shift_threshold_for_basis
    end

    success_value = blue_shift.basis_triggered_value + 0.5
    if success_value > Metric.blue_shift_threshold_for_basis
      return Metric.blue_shift_threshold_for_basis
    end
    
    return success_value
  end

  def blue_shift_form_needed_for_basis?
    return basis < Metric.blue_shift_threshold_for_basis
  end

  def average_rent_delta_percent_level
    if !average_rent_delta_percent.nil?
     return 1 if average_rent_delta_percent > 0
     return 2 if average_rent_delta_percent == 0 || average_rent_delta_percent > -1
     return 3 if average_rent_delta_percent == -1 || average_rent_delta_percent > -2
     return 6 if average_rent_delta_percent <= -2
    end

    return nil
  end

  def leases_attained_adjusted
    if leases_attained.nil? || leases_goal.nil?
      return nil
    end
    
    return leases_attained
  end

  def total_lease_goal_adjusted
    if leases_attained.nil? || leases_goal.nil?
      return nil
    end
    
    total_lease_goal_num = leases_attained + leases_goal

    # If total goal is <= zero, adjust attained and total goal, for bluebot graphic and messaging
    if total_lease_goal_num < 0
      total_lease_goal_num = 0
    end

    return total_lease_goal_num
  end

  def percent_of_lease_goal_adjusted
    if leases_attained.nil? || leases_goal.nil?
      return nil
    end

    leases_attained_num = leases_attained
    total_lease_goal_num = leases_attained + leases_goal

    return Metric.calc_percentage(leases_attained_num, total_lease_goal_num)
  end

  def self.calc_percentage(numerator, denominator) 
    if denominator <= 0 
        percentage = numerator.to_f / 1.0 * 100.0
    else # denominator > 0
      percentage = numerator.to_f / denominator.to_f * 100.0
    end

    return percentage
  end

  def self.average_basis(metrics)
    if metrics.nil? || metrics.count == 0
      return 0.0
    end

    sum = 0.0
    metrics.each do |metric| 
      if metric.basis.present?
        sum += metric.basis
      end
    end

    return sum / metrics.count
  end

  def self.average_physical_occupancy(metrics)
    if metrics.nil? || metrics.count == 0
      return 0.0
    end

    sum = 0.0
    metrics.each do |metric|
      if metric.physical_occupancy.present?
        sum += metric.physical_occupancy
      end
    end

    return sum / metrics.count
  end

  def self.average_trending_average_daily(metrics)
    if metrics.nil? || metrics.count == 0
      return 0.0
    end

    sum = 0.0
    metrics.each do |metric| 
      if metric.trending_average_daily.present?
        sum += metric.trending_average_daily
      end 
    end

    return sum / metrics.count
  end

  def self.average_trending_next_month(metrics)
    if metrics.nil? || metrics.count == 0
      return 0.0
    end

    sum = 0.0
    metrics.each do |metric| 
      if metric.trending_next_month.present?
        sum += metric.trending_next_month
      end
    end

    return sum / metrics.count
  end

  def self.average_rolling_10_net_sales(metrics)
    if metrics.nil? || metrics.count == 0
      return 0.0
    end

    sum = 0.0
    metrics.each do |metric| 
      if metric.rolling_10_net_sales.present?
        sum += metric.rolling_10_net_sales
      end
    end

    return sum / metrics.count
  end

  def self.average_rolling_30_net_sales(metrics)
    if metrics.nil? || metrics.count == 0
      return 0.0
    end

    sum = 0.0
    metrics.each do |metric| 
      if metric.rolling_30_net_sales.present?
        sum += metric.rolling_30_net_sales
      end
    end

    return sum / metrics.count
  end
  

  private
  def get_metric_level(value, x, y, z)
    if value.nil?
      return nil
    end

    return 1 if value >= x
    return 2 if value >= y and value < x
    return 3 if value >= z and value < y
    return 6 if value < z    
    
    return nil
  end
  
  def get_metric_level_using_percentage_of_units(value)
    if value.nil?
      return nil
    end
    
    return 1 if value == 0
    return 2 if value / number_of_units < 0.05
    return 3 if value / number_of_units < 0.10
    return 6 if value / number_of_units >= 0.10
    return nil
  end

end
