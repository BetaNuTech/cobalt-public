module ConversionsForAgentsChartData

  def self.portfolio_collect_data(text_date, cfa_attribute)
    cfa_date = Date.parse(text_date)
    beginning_date = cfa_date - 12.months
    
    if cfa_attribute == 'prospects_30days'
      columns = ["date", cfa_attribute, 'num_of_leads_needed', 'druid_prospects_30days']
    
      data = ConversionsForAgent
        .where("date >= ? AND date <= ?", beginning_date, cfa_date)
        .where(is_property_data: true)
        .order(:date)
        .pluck(*columns)

      chart_data = combine_and_collect_prospects_30days_data(data)
          
      set_moving_averages(chart_data)
    else 
      columns = ["date", cfa_attribute]
    
      data = ConversionsForAgent
        .where("date >= ? AND date <= ?", beginning_date, cfa_date)
        .where(is_property_data: true)
        .order(:date)
        .pluck(*columns)
        
      chart_data = combine_and_collect_y_data(data)

      set_moving_averages(chart_data)
    end

    return chart_data
  end

  def self.team_collect_data(text_date, team_id, cfa_attribute)
    cfa_date = Date.parse(text_date)
    beginning_date = cfa_date - 12.months

    # gather team property codes
    team = Property.find(team_id)
    team_property_codes = Property.properties.where(active: true, team_id: team).pluck('code')

    if cfa_attribute == 'prospects_30days'
      columns = ["date", cfa_attribute, 'num_of_leads_needed', 'druid_prospects_30days']
    
      data = ConversionsForAgent
        .where("date >= ? AND date <= ?", beginning_date, cfa_date)
        .where(agent: team_property_codes)
        .order(:date)
        .pluck(*columns)

      chart_data = combine_and_collect_prospects_30days_data(data)
          
      set_moving_averages(chart_data)
    else 
      columns = ["date", cfa_attribute]
    
      data = ConversionsForAgent
        .where("date >= ? AND date <= ?", beginning_date, cfa_date)
        .where(agent: team_property_codes)
        .order(:date)
        .pluck(*columns)
        
      chart_data = combine_and_collect_y_data(data)

      set_moving_averages(chart_data)
    end

    return chart_data
  end

  def self.collect_data(cfa, cfa_attribute)
    beginning_date = cfa.date - 12.months
    
    if cfa_attribute == 'prospects_30days'
      columns = ["date", cfa_attribute, 'num_of_leads_needed', 'druid_prospects_30days']
    
      data = ConversionsForAgent
        .where("date >= ? AND date <= ?", beginning_date, cfa.date)
        .where(agent: cfa.agent)
        .order(:date)
        .pluck(*columns)
        
      last_non_nil_value_one = 0.0
      last_non_nil_value_two = 0.0
      last_non_nil_value_three = 0.0
      chart_data = data.reverse.collect { |d|
        value_one = d[1].to_f
        value_two = d[2].to_f
        value_three = d[3].to_f
        if !d[1].nil?
          last_non_nil_value_one = value_one
        else
          value_one = last_non_nil_value_one
        end
        if !d[2].nil?
          last_non_nil_value_two = value_two
        else
          value_two = last_non_nil_value_two
        end
        if !d[3].nil?
          last_non_nil_value_three = value_three
        else
          value_three = last_non_nil_value_three
        end
        { x: d[0], y: value_one, num_of_leads_needed: value_two, druid_prospects_30days: value_three }
      }.reverse
      set_moving_averages(chart_data)
    else 
      columns = ["date", cfa_attribute]
    
      data = ConversionsForAgent
        .where("date >= ? AND date <= ?", beginning_date, cfa.date)
        .where(agent: cfa.agent)
        .order(:date)
        .pluck(*columns)
      
      last_non_nil_value = 0.0
      chart_data = data.reverse.collect { |d|
        if !d[1].nil?
          last_non_nil_value = d[1].to_f
          { x: d[0], y: d[1].to_f }
        else
          { x: d[0], y: last_non_nil_value }
        end
      }.reverse
      set_moving_averages(chart_data)
    end


    return chart_data
  end

  def self.valid_cfa_attributes
    ['prospects_30days']
  end
  
  private

  def self.set_moving_averages(chart_data)
    values = chart_data.collect { |m| m[:y] }
    
    for i in (0...chart_data.length)
      if i < 30
        sma_period = i + 1
      else
        sma_period = 30
      end
      
      chart_data[i][:moving_average]= values.sma(i, sma_period)
    end
  end

  def self.combine_and_collect_prospects_30days_data(data)
    date = ""
    chart_data = []
    data_combined_value_one = 0.0
    data_combined_value_two = 0.0
    data_combined_value_three = 0.0
    all_data_value_one_nil = true
    all_data_value_two_nil = true
    all_data_value_three_nil = true
    last_non_nil_commbined_value_one = 0.0
    last_non_nil_commbined_value_two = 0.0
    last_non_nil_commbined_value_three = 0.0
    data.reverse.each do |d|
      if date == ""
        date = d[0]
      end
      if date == d[0]
        data_combined_value_one += d[1].to_f
        data_combined_value_two += d[2].to_f
        data_combined_value_three += d[3].to_f
        all_data_value_one_nil = false if !d[1].nil?
        all_data_value_two_nil = false if !d[2].nil?
        all_data_value_three_nil = false if !d[3].nil?
      else
        if all_data_value_one_nil
          data_combined_value_one = last_non_nil_commbined_value_one
        else
          last_non_nil_commbined_value_one = data_combined_value_one
        end
        if all_data_value_two_nil
          data_combined_value_two = last_non_nil_commbined_value_two
        else
          last_non_nil_commbined_value_two = data_combined_value_two
        end
        if all_data_value_three_nil
          data_combined_value_three = last_non_nil_commbined_value_three
        else
          last_non_nil_commbined_value_three = data_combined_value_three
        end
        chart_data.insert(0, { 
          x: date, 
          y: data_combined_value_one, 
          num_of_leads_needed: data_combined_value_two, 
          druid_prospects_30days: data_combined_value_three
        })
        date = d[0]
        data_combined_value_one = d[1].to_f
        data_combined_value_two = d[2].to_f
        data_combined_value_three = d[3].to_f
        all_data_value_one_nil = true
        all_data_value_two_nil = true
        all_data_value_three_nil = true    
        all_data_value_one_nil = false if !d[1].nil?
        all_data_value_two_nil = false if !d[2].nil?
        all_data_value_three_nil = false if !d[3].nil?
      end
    end

    return chart_data
  end

  def self.combine_and_collect_y_data(data)
    date = ""
    chart_data = []
    data_combined_value_one = 0.0
    all_data_value_one_nil = true
    last_non_nil_commbined_value_one = 0.0
    data.reverse.each do |d|
      if date == ""
        date = d[0]
      end
      if date == d[0]
        data_combined_value_one += d[1].to_f
        all_data_value_one_nil = false if !d[1].nil?
      else
        if all_data_value_one_nil
          data_combined_value_one = last_non_nil_commbined_value_one
        else
          last_non_nil_commbined_value_one = data_combined_value_one
        end
        chart_data.insert(0, { 
          x: date, 
          y: data_combined_value_one, 
        })
        date = d[0]
        data_combined_value_one = d[1].to_f
        all_data_value_one_nil = true
        all_data_value_one_nil = false if !d[1].nil?
      end
    end

    return chart_data
  end

end
