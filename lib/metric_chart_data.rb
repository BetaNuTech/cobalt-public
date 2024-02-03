module MetricChartData

  def self.collect_data(metric, metric_attribute)
    beginning_date = metric.date - 12.months
    
    columns = ["date", metric_attribute]
    if metric_attribute == "average_rents_net_effective"  
      columns << "average_rents_net_effective_budgeted"
    end
    
    data = Metric
      .where("date >= ? AND date <= ?", beginning_date, metric.date)
      .where(property: metric.property)
      .order(:date)
      .pluck(*columns)
      
    # last_non_nil_value = nil
    metric_data = data.reverse.collect { |d|
      if !d[1].nil?
        # last_non_nil_value = d[1].to_f
        { x: d[0], y: d[1].to_f }
      else
        { x: d[0], y: nil }
      end
    }.reverse

    # Remove recent nil values
    metric_data = metric_data.select { |d| d[:y] != nil }

    if (metric_data.nil? || metric_data.empty?) && data.present?
      metric_data = [{ x: data.last[0], y: 0.0 }]
    end

    set_moving_averages(metric_data)
    set_budget(data, metric_attribute, metric_data)

    return metric_data
  end

  def self.valid_metric_attributes
    ['physical_occupancy', 'rolling_30_net_sales', 'rolling_10_net_sales', 'cnoi', 'trending_average_daily',
      'trending_next_month', 'occupancy_average_daily', 'occupancy_budgeted_economic', 'average_market_rent', 'average_rents_net_effective',
      'average_rents_net_effective_budgeted', 'average_rent_weighted_per_unit_specials', 'average_rent_year_over_year_without_vacancy', 'average_rent_year_over_year_with_vacancy', 
      'basis', 'basis_year_to_date', 
      'renewals_unknown', 'renewals_number_renewed', 'renewals_percentage_renewed', 'renewals_residents_month_to_month', 'collections_current_status_residents_with_last_month_balance', 'collections_unwritten_off_balances', 
      'collections_percentage_recurring_charges_collected', 'collections_current_status_residents_with_current_month_balance', 'collections_number_of_eviction_residents',
      'maintenance_percentage_ready_over_vacant', 'maintenance_number_not_ready', 'maintenance_turns_completed', 'maintenance_open_wos', 'maintenance_total_open_work_orders', 'maintenance_vacants_over_nine_days',
      'average_rent_1bed_net_effective', 'average_rent_1bed_new_leases', 'average_rent_1bed_renewal_leases',
      'average_rent_2bed_net_effective', 'average_rent_2bed_new_leases', 'average_rent_2bed_renewal_leases',
      'average_rent_3bed_net_effective', 'average_rent_3bed_new_leases', 'average_rent_3bed_renewal_leases',
      'average_rent_4bed_net_effective', 'average_rent_4bed_new_leases', 'average_rent_4bed_renewal_leases'
    ]

    # Hidden, since no longer used
    # occupancy_average_daily_30_days_ago
  end
  
  private
  def self.set_moving_averages(metric_data)
    values = metric_data.collect { |m| m[:y] }
    
    for i in (0...metric_data.length)
      if i < 30
        sma_period = i + 1
      else
        sma_period = 30
      end
      
      metric_data[i][:moving_average]= values.sma(i, sma_period)
    end
  end
  
  def self.set_budget(data, metric_attribute, metric_data)
    metric_data.each_with_index do |m, index|
      case metric_attribute
      when "cnoi"
        m[:budget] = 100
      when "physical_occupancy"
        m[:budget] = 95
      when "trending_average_daily"
        m[:budget] = 92
      when "occupancy_average_daily"
        m[:budget] = 95
      when "average_rents_net_effective"
        m[:budget] = data[index][2].to_f
      when "basis"
        m[:budget] = 100
      when "renewals_percentage_renewed"
        m[:budget] = 50
      end      
    end    
  end

end
