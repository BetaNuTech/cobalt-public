module CollectionsDetailChartData

  def self.collect_data(collections_detail, attribute)
    beginning_date = collections_detail.date_time - 12.months
    
    columns = ["date_time", attribute]
    if attribute == "total_paid" || attribute == "total_payment_plan" || attribute == "total_evictions_owed"
      columns << "total_charges"
    end

    data = CollectionsDetail
      .where("date_time >= ? AND date_time <= ?", beginning_date, collections_detail.date_time)
      .where(property: collections_detail.property)
      .order(:date_time)
      .pluck(*columns)
      
    last_non_nil_value = 0.0
    collections_detail_data = data.reverse.collect { |d|
      if !d[1].nil?
        if attribute == "total_paid" || attribute == "total_payment_plan" || attribute == "total_evictions_owed"
          last_non_nil_value = (d[1].to_f / d[2].to_f) * 100.0
        elsif attribute == "covid_adjusted_rents"
          last_non_nil_value = d[1].to_f.abs()
        else
          last_non_nil_value = d[1].to_f
        end
        { x: d[0], y: last_non_nil_value }
      else
        { x: d[0], y: last_non_nil_value }
      end
    }.reverse

    # set_moving_averages(collections_detail_data)

    return collections_detail_data
  end
  
  private
  def self.set_moving_averages(collections_detail_data)
    values = collections_detail_data.collect { |m| m[:y] }
    
    for i in (0...collections_detail_data.length)
      if i < 30
        sma_period = i + 1
      else
        sma_period = 30
      end
      
      collections_detail_data[i][:moving_average]= values.sma(i, sma_period)
    end
  end

end
