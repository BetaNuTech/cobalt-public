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
require 'test_helper'

class MetricTest < ActiveSupport::TestCase
  
  def setup 
    @metric = metrics(:one)
    @metric.occupancy_average_daily = 100
    @metric.save!
  end
  test "require property" do
    @metric.property = nil
    @metric.valid?
    assert @metric.errors[:property].length > 0, "no validation error"    
  end
  
  test "require date" do
    @metric.date = nil
    @metric.valid?
    assert @metric.errors[:date].length > 0, "no validation error"    
  end
  
  test "require position" do
    @metric.position = nil
    @metric.valid?
    assert @metric.errors[:position].length > 0, "no validation error"    
  end
  
  test "physical_occupancy_level returns 1" do
    @metric.physical_occupancy = 96
    assert_equal 1, @metric.physical_occupancy_level
  end

  test "physical_occupancy_level returns 2" do
    @metric.physical_occupancy = 94
    assert_equal 2, @metric.physical_occupancy_level  
  end
  
  test "physical_occupancy_level returns 3" do
    @metric.physical_occupancy = 92
    assert_equal 3, @metric.physical_occupancy_level
  end
  

  test "physical_occupancy_level returns 4" do
    @metric.physical_occupancy = 90
    assert_equal 4, @metric.physical_occupancy_level    
  end
  
  test "cnoi_level returns 1" do
    @metric.cnoi = 101
    assert_equal 1, @metric.cnoi_level
  end

  test "cnoi_level returns 2" do
    @metric.cnoi = 100
    assert_equal 2, @metric.cnoi_level  
  end
  
  test "cnoi_level returns 3" do
    @metric.cnoi = 99
    assert_equal 3, @metric.cnoi_level
  end
  
  test "cnoi_level returns 4" do
    @metric.cnoi = 98
    assert_equal 4, @metric.cnoi_level    
  end
  
  test "trending_average_daily_level returns 1" do
    @metric.trending_average_daily = 95
    assert_equal 1, @metric.trending_average_daily_level
  end

  test "trending_average_daily_level returns 2" do
    @metric.trending_average_daily = 93
    assert_equal 2, @metric.trending_average_daily_level  
  end
  
  test "trending_average_daily_level returns 3" do
    @metric.trending_average_daily = 91
    assert_equal 3, @metric.trending_average_daily_level
  end
  
  test "trending_average_daily_level returns 4" do
    @metric.trending_average_daily = 89
    assert_equal 4, @metric.trending_average_daily_level    
  end
  
  test "trending_next_month_level returns 1" do
    @metric.trending_next_month = 92
    assert_equal 1, @metric.trending_next_month_level
  end

  test "trending_next_month_level returns 2" do
    @metric.trending_next_month = 91
    assert_equal 2, @metric.trending_next_month_level  
  end
  
  test "trending_next_month_level returns 3" do
    @metric.trending_next_month = 89
    assert_equal 3, @metric.trending_next_month_level
  end
  
  test "trending_next_month_level returns 4" do
    @metric.trending_next_month = 85
    assert_equal 4, @metric.trending_next_month_level    
  end
  
  test "occupancy_average_daily_level returns 1" do
    @metric.occupancy_average_daily = 95
    assert_equal 1, @metric.occupancy_average_daily_level
  end

  test "occupancy_average_daily_level returns 2" do
    @metric.occupancy_average_daily = 92
    assert_equal 2, @metric.occupancy_average_daily_level  
  end
  
  test "occupancy_average_daily_level returns 3" do
    @metric.occupancy_average_daily = 90
    assert_equal 3, @metric.occupancy_average_daily_level
  end
  
  test "occupancy_average_daily_level returns 4" do
    @metric.occupancy_average_daily = 89
    assert_equal 4, @metric.occupancy_average_daily_level    
  end
  
  test "average_rents_net_effective_level returns 1" do
    @metric.average_rents_net_effective = 1200
    @metric.average_rents_net_effective_budgeted = 1000

    assert_equal 1, @metric.average_rents_net_effective_level
  end

  test "average_rents_net_effective_level returns 2 when greater than" do
    @metric.average_rents_net_effective = 1001
    @metric.average_rents_net_effective_budgeted = 1000
    
    assert_equal 2, @metric.average_rents_net_effective_level  
  end
  
  test "average_rents_net_effective_level returns 2 when equal" do
    @metric.average_rents_net_effective = 1000
    @metric.average_rents_net_effective_budgeted = 1000
    
    assert_equal 2, @metric.average_rents_net_effective_level  
  end
  
  test "average_rents_net_effective_level returns 3" do
    @metric.average_rents_net_effective = 980
    @metric.average_rents_net_effective_budgeted = 1000
    
    assert_equal 3, @metric.average_rents_net_effective_level
  end
  
  test "average_rents_net_effective_level returns 4" do
    @metric.average_rents_net_effective = 900
    @metric.average_rents_net_effective_budgeted = 1000
    
    assert_equal 4, @metric.average_rents_net_effective_level    
  end
  
  test "basis_level returns 1" do
    @metric.basis = 101
    assert_equal 1, @metric.basis_level
  end

  test "basis_level returns 2" do
    @metric.basis = 100
    assert_equal 2, @metric.basis_level  
  end
  
  test "basis_level returns 3" do
    @metric.basis = 99
    assert_equal 3, @metric.basis_level
  end
  
  test "basis_level returns 4" do
    @metric.basis = 98
    assert_equal 4, @metric.basis_level    
  end
  
  test "basis_year_to_date_level returns 1" do
    @metric.basis_year_to_date = 101
    assert_equal 1, @metric.basis_year_to_date_level
  end

  test "basis_year_to_date_level returns 2" do
    @metric.basis_year_to_date = 100
    assert_equal 2, @metric.basis_year_to_date_level  
  end
  
  test "basis_year_to_date_level returns 3" do
    @metric.basis_year_to_date = 99
    assert_equal 3, @metric.basis_year_to_date_level
  end
  
  test "basis_year_to_date_level returns 4" do
    @metric.basis_year_to_date = 98
    assert_equal 4, @metric.basis_year_to_date_level    
  end

  test "expenses_percentage_of_budget_level returns 1" do
    @metric.expenses_percentage_of_budget = 94
    
    assert_equal 1, @metric.expenses_percentage_of_budget_level
  end

  test "expenses_percentage_of_budget_level returns 2" do
    @metric.expenses_percentage_of_budget = 100.5
    
    assert_equal 2, @metric.expenses_percentage_of_budget_level
  end
  
  test "expenses_percentage_of_budget_level returns 3" do
    @metric.expenses_percentage_of_budget = 102
    
    assert_equal 3, @metric.expenses_percentage_of_budget_level
  end

  test "expenses_percentage_of_budget_level returns 4" do
    @metric.expenses_percentage_of_budget = 103.1
    
    assert_equal 4, @metric.expenses_percentage_of_budget_level
  end

  test "expenses_percentage_of_past_month_level returns 1" do
    @metric.expenses_percentage_of_budget = 94
    @metric.expenses_percentage_of_past_month = 100
    
    assert_equal 1, @metric.expenses_percentage_of_past_month_level
  end

  test "expenses_percentage_of_past_month_level returns 2 if a little below" do
    @metric.expenses_percentage_of_budget = 96
    @metric.expenses_percentage_of_past_month = 100
    
    assert_equal 2, @metric.expenses_percentage_of_past_month_level  
  end
  
  test "expenses_percentage_of_past_month_level returns 2 if a little above" do
    @metric.expenses_percentage_of_budget = 103
    @metric.expenses_percentage_of_past_month = 100
    
    assert_equal 2, @metric.expenses_percentage_of_past_month_level  
  end
  
  test "expenses_percentage_of_past_month_level returns 2 if equal" do
    @metric.expenses_percentage_of_budget = 100
    @metric.expenses_percentage_of_past_month = 100
    
    assert_equal 2, @metric.expenses_percentage_of_past_month_level  
  end
  
  test "expenses_percentage_of_past_month_level returns 3" do
    @metric.expenses_percentage_of_budget = 106
    @metric.expenses_percentage_of_past_month = 100
    
    assert_equal 3, @metric.expenses_percentage_of_past_month_level
  end
  
  test "expenses_percentage_of_past_month_level returns 4" do
    @metric.expenses_percentage_of_budget = 111
    @metric.expenses_percentage_of_past_month = 100
    
    assert_equal 4, @metric.expenses_percentage_of_past_month_level
  end
  
  test "renewals_percentage_renewed_level returns 1" do
    @metric.renewals_percentage_renewed = 51
    assert_equal 1, @metric.renewals_percentage_renewed_level
  end

  test "renewals_percentage_renewed_level returns 2" do
    @metric.renewals_percentage_renewed = 50  
    assert_equal 2, @metric.renewals_percentage_renewed_level  
  end
  
  test "renewals_percentage_renewed_level returns 3" do
    @metric.renewals_percentage_renewed = 44
    assert_equal 3, @metric.renewals_percentage_renewed_level
  end
  
  test "renewals_percentage_renewed_level returns 4" do
    @metric.renewals_percentage_renewed = 39
    assert_equal 4, @metric.renewals_percentage_renewed_level    
  end
  
  test "collections_current_status_residents_with_last_month_balance_level returns 1" do
    @metric.collections_current_status_residents_with_last_month_balance = 0
    assert_equal 1, @metric.collections_current_status_residents_with_last_month_balance_level
  end

  test "collections_current_status_residents_with_last_month_balance_level returns 2" do
    @metric.collections_current_status_residents_with_last_month_balance = 1
    assert_equal 2, @metric.collections_current_status_residents_with_last_month_balance_level  
  end
  
  test "collections_current_status_residents_with_last_month_balance_level returns 3" do
    @metric.collections_current_status_residents_with_last_month_balance = 2
    assert_equal 3, @metric.collections_current_status_residents_with_last_month_balance_level
  end
  
  test "collections_current_status_residents_with_last_month_balance_level returns 4" do
    @metric.collections_current_status_residents_with_last_month_balance = 3
    assert_equal 4, @metric.collections_current_status_residents_with_last_month_balance_level    
  end
  
  test "collections_unwritten_off_balances_level returns 1" do
    @metric.collections_unwritten_off_balances = 0
    assert_equal 1, @metric.collections_unwritten_off_balances_level
  end

  test "collections_unwritten_off_balances_level returns 2" do
    @metric.collections_unwritten_off_balances = 4
    @metric.number_of_units = 100
    assert_equal 2, @metric.collections_unwritten_off_balances_level  
  end
  
  test "collections_unwritten_off_balances_level returns 3" do
    @metric.collections_unwritten_off_balances = 8
    @metric.number_of_units = 100
    assert_equal 3, @metric.collections_unwritten_off_balances_level
  end
  
  test "collections_unwritten_off_balances_level returns 4" do
    @metric.collections_unwritten_off_balances = 11
    @metric.number_of_units = 100
    assert_equal 4, @metric.collections_unwritten_off_balances_level    
  end
  
  test "collections_percentage_recurring_charges_collected_level returns 1 before 5th of month" do
    @metric.date = Date.new(2016, 1, 3)
    @metric.collections_percentage_recurring_charges_collected = 99.1
    assert_equal 1, @metric.collections_percentage_recurring_charges_collected_level
  end
  
  test "collections_percentage_recurring_charges_collected_level returns 1 after 5th of month" do
    @metric.date = Date.new(2016, 1, 6)
    @metric.collections_percentage_recurring_charges_collected = 100
    assert_equal 1, @metric.collections_percentage_recurring_charges_collected_level
  end

  test "collections_percentage_recurring_charges_collected_level returns 2 before 5th of month" do
    @metric.date = Date.new(2016, 1, 3)
    @metric.collections_percentage_recurring_charges_collected = 98.5
    assert_equal 2, @metric.collections_percentage_recurring_charges_collected_level
  end
  
  test "collections_percentage_recurring_charges_collected_level returns 2 after 5th of month" do
    @metric.date = Date.new(2016, 1, 6)
    @metric.collections_percentage_recurring_charges_collected = 99
    assert_equal 2, @metric.collections_percentage_recurring_charges_collected_level
  end
  
  test "collections_percentage_recurring_charges_collected_level returns 3 before 5th of month" do
    @metric.date = Date.new(2016, 1, 3)
    @metric.collections_percentage_recurring_charges_collected = 96
    assert_equal 3, @metric.collections_percentage_recurring_charges_collected_level
  end
  
  test "collections_percentage_recurring_charges_collected_level returns 3 after 5th of month" do
    @metric.date = Date.new(2016, 1, 6)
    @metric.collections_percentage_recurring_charges_collected = 98
    assert_equal 3, @metric.collections_percentage_recurring_charges_collected_level
  end
  
  test "collections_percentage_recurring_charges_collected_level returns 4 before 5th of month" do
    @metric.date = Date.new(2016, 1, 3)
    @metric.collections_percentage_recurring_charges_collected = 94
    assert_equal 4, @metric.collections_percentage_recurring_charges_collected_level
  end
  
  test "collections_percentage_recurring_charges_collected_level returns 4 after 5th of month" do
    @metric.date = Date.new(2016, 1, 6)
    @metric.collections_percentage_recurring_charges_collected = 97
    assert_equal 4, @metric.collections_percentage_recurring_charges_collected_level
  end
  
  test "collections_current_status_residents_with_current_month_balance_level returns 1" do
    @metric.collections_current_status_residents_with_current_month_balance = 0
    assert_equal 1, @metric.collections_current_status_residents_with_current_month_balance_level
  end

  test "collections_current_status_residents_with_current_month_balance_level returns 2" do
    @metric.collections_current_status_residents_with_current_month_balance = 4
    @metric.number_of_units = 100
    assert_equal 2, @metric.collections_current_status_residents_with_current_month_balance_level  
  end

  test "collections_current_status_residents_with_current_month_balance_level returns 3" do
    @metric.collections_current_status_residents_with_current_month_balance = 8
    @metric.number_of_units = 100
    assert_equal 3, @metric.collections_current_status_residents_with_current_month_balance_level
  end

  test "collections_current_status_residents_with_current_month_balance_level returns 4" do
    @metric.collections_current_status_residents_with_current_month_balance = 11
    @metric.number_of_units = 100
    assert_equal 4, @metric.collections_current_status_residents_with_current_month_balance_level    
  end
  
  test "collections_number_of_eviction_residents_level returns 1" do
    @metric.collections_number_of_eviction_residents = 0
    assert_equal 1, @metric.collections_number_of_eviction_residents_level
  end

  test "collections_number_of_eviction_residents_level returns 2" do
    @metric.collections_number_of_eviction_residents = 4
    @metric.number_of_units = 100
    assert_equal 2, @metric.collections_number_of_eviction_residents_level  
  end

  test "collections_number_of_eviction_residents_level returns 3" do
    @metric.collections_number_of_eviction_residents = 8
    @metric.number_of_units = 100
    assert_equal 3, @metric.collections_number_of_eviction_residents_level
  end

  test "collections_number_of_eviction_residents_level returns 4" do
    @metric.collections_number_of_eviction_residents = 11
    @metric.number_of_units = 100
    assert_equal 4, @metric.collections_number_of_eviction_residents_level    
  end
  
  test "maintenance_percentage_ready_over_vacant_level returns 1" do
    @metric.maintenance_percentage_ready_over_vacant = 99.5
    assert_equal 1, @metric.maintenance_percentage_ready_over_vacant_level
  end

  test "maintenance_percentage_ready_over_vacant_level returns 2" do
    @metric.maintenance_percentage_ready_over_vacant = 96
    assert_equal 2, @metric.maintenance_percentage_ready_over_vacant_level  
  end
  
  test "maintenance_percentage_ready_over_vacant_level returns 3" do
    @metric.maintenance_percentage_ready_over_vacant = 92
    assert_equal 3, @metric.maintenance_percentage_ready_over_vacant_level
  end
  
  test "maintenance_percentage_ready_over_vacant_level returns 4" do
    @metric.maintenance_percentage_ready_over_vacant = 89
    assert_equal 4, @metric.maintenance_percentage_ready_over_vacant_level    
  end
  
  test "maintenance_number_not_ready_level returns 1" do
    @metric.maintenance_number_not_ready = 0
    assert_equal 1, @metric.maintenance_number_not_ready_level
  end

  test "maintenance_number_not_ready_level returns 2" do
    @metric.maintenance_number_not_ready = 2
    @metric.number_of_units = 100
    assert_equal 2, @metric.maintenance_number_not_ready_level  
  end
  
  test "maintenance_number_not_ready_level returns 3" do
    @metric.maintenance_number_not_ready = 3
    @metric.number_of_units = 100
    assert_equal 3, @metric.maintenance_number_not_ready_level
  end
  
  test "maintenance_number_not_ready_level returns 4" do
    @metric.maintenance_number_not_ready = 5
    @metric.number_of_units = 100
    assert_equal 4, @metric.maintenance_number_not_ready_level    
  end
  
  test "maintenance_open_wos_level returns 1" do
    @metric.maintenance_open_wos = 0
    assert_equal 1, @metric.maintenance_open_wos_level
  end

  test "maintenance_open_wos_level returns 2" do
    @metric.maintenance_open_wos = 1.5
    @metric.number_of_units = 100
    assert_equal 2, @metric.maintenance_open_wos_level  
  end
  
  test "maintenance_open_wos_level returns 3 if greater than 10" do
    @metric.maintenance_open_wos = 11
    @metric.number_of_units = 10000
    assert_equal 3, @metric.maintenance_open_wos_level
  end
  
  test "maintenance_open_wos_level returns 3 if greater than or equal to 2%" do
    @metric.maintenance_open_wos = 2
    @metric.number_of_units = 100
    assert_equal 3, @metric.maintenance_open_wos_level
  end
  
  test "maintenance_open_wos_level returns 4 if greater than 20" do
    @metric.maintenance_open_wos = 21
    @metric.number_of_units = 10000
    assert_equal 4, @metric.maintenance_open_wos_level
  end
  
  test "maintenance_open_wos_level returns 4 if greater than or equal to 2%" do
    @metric.maintenance_open_wos = 5
    @metric.number_of_units = 100
    assert_equal 4, @metric.maintenance_open_wos_level
  end
  
  test "returns blue_shift_form_needed if basis over level 2" do
    @metric.basis = 99
    @metric.date = Date.new(2017,8,3)
    @metric.physical_occupancy = 96
    @metric.trending_average_daily = 93
    
    assert_equal true, @metric.basis_level > 2
  end
  
  test "returns blue_shift_form_needed if physical_occupancy_level over level 2" do
    @metric.basis = 101
    @metric.physical_occupancy = 91
    @metric.trending_average_daily = 100
    
    assert_equal true, @metric.blue_shift_form_needed?
  end
  
  test "returns blue_shift_form_needed if trending_average_daily over level 2" do
    @metric.basis = 101
    @metric.physical_occupancy = 96
    @metric.trending_average_daily = 89
    
    assert_equal true, @metric.blue_shift_form_needed?
  end
  
  
  
end
