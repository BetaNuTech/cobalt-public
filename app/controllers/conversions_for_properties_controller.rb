class ConversionsForPropertiesController < ApplicationController
  include ActionView::Helpers::NumberHelper
  
  # GET /conversions_for_properties/:date
  # GET /conversions_for_properties/:date.json
  def show
    if params[:date].present?
      # @date = Date.parse params[:date]
      @date = Date.strptime(params[:date], "%m/%d/%Y")
    else
      # @date = Time.now.to_date - 1.day # Previous day
      @date = Time.now.to_date
    end
    # @date = params[:date]

    @property_id = params[:property_id]
    if @property_id.nil? 
      @team_code = 'All'
      @team_codes = Team.where(active: true).order("code ASC").pluck('code')
      @team_codes.unshift(@team_code)
  
      # team_code selected
      if params[:team_code]
        @team_code = params[:team_code]
        if params[:team_code] != "All"
          @team_selected = Property.where(code: params[:team_code]).first
        end
      elsif current_user.team_code
        @team_code = current_user.team_code
        @team_selected = Property.where(code: @team_code).first
      end
    end

    respond_to do |format|
      format.html
      format.json do 
        render_datatables
      end
    end

  end
  
  private
  def render_datatables

    if @property_id
      property = Property.find(@property_id)
      if !property.nil?
        @conversions_for_properties = ConversionsForAgent.where(date: @date, agent: property.code)
      end
    elsif @team_selected.nil?
      @conversions_for_properties = ConversionsForAgent.where(date: @date, is_property_data: true).order("agent ASC")
    else
      team_property_codes = Property.properties.where(active: true, team_id: @team_selected).pluck('code')
      @conversions_for_properties = ConversionsForAgent.where(date: @date, is_property_data: true, agent: team_property_codes).order("agent ASC")
    end
    
    @data = calculate_data
    set_ordering
    data_tables = create_data_tables
    render json: data_tables.as_json
  end
  
  def create_data_tables
    data_tables = {
         data: create_table_data
       }
       
    return data_tables    
  end
  
  def calculate_data
    druid_prospect_stats = StatRecord.druidProspectStats(@date)

    table_data = @conversions_for_properties.collect do |cfa|
      metrics = cfa.property_metrics()

      property_metric = Metric.where(property: cfa.property, date: @date).first
      if !property_metric.nil?
        occupancy_average_daily = property_metric.occupancy_average_daily
        occupancy_level = property_metric.occupancy_average_daily_level
        trending_average_daily = property_metric.trending_average_daily
        trending_level = property_metric.trending_average_daily_level       
      else
        occupancy_average_daily = nil
        occupancy_level = nil
        trending_average_daily = nil
        trending_level = nil        
      end

      if trending_level == 3 && leads_reported_level(metrics[:num_of_leads_needed], cfa.prospects_30days) >= 3
        agent_level = 3
      elsif trending_level == 6 && leads_reported_level(metrics[:num_of_leads_needed], cfa.prospects_30days) >= 3
        agent_level = 6
      else
        agent_level = 0
      end

      druid_prospects_30days = ''
      druid_prospects_all_30days = ''
      prospects_30days_delta = ''
      if !druid_prospect_stats.nil?
        druidProspectStatsForProperty = druid_prospect_stats.druidProspectStatsForProperty(cfa.property.code)
        if !druidProspectStatsForProperty.nil?
          value = druidProspectStatsForProperty['Prospects30']
          value_all = druidProspectStatsForProperty['Prospects30_all']
          if !value.nil?
            druid_prospects_30days = "#{number(value)}"
            delta = value - cfa.prospects_30days
            if delta > 0
              prospects_30days_delta = "+#{number(delta)}"
            else
              prospects_30days_delta = "#{number(delta)}"
            end
          end
          if !value_all.nil?
            druid_prospects_all_30days = "#{number(value_all)}"
          end
        end
      else
        druid_property_prospect_stats = StatRecord.druidPropertyProspectStats(@date, cfa.property.code)
        if !druid_property_prospect_stats.nil?
          druidProspectStatsForProperty = druid_property_prospect_stats.druidProspectStatsForProperty(cfa.property.code)
          if !druidProspectStatsForProperty.nil?
            value = druidProspectStatsForProperty['Prospects30']
            value_all = druidProspectStatsForProperty['Prospects30_all']
            if !value.nil?
              druid_prospects_30days = "#{number(value)}"
              delta = value - cfa.prospects_30days
              if delta > 0
                prospects_30days_delta = "+#{number(delta)}"
              else
                prospects_30days_delta = "#{number(delta)}"
              end
            end
            if !value_all.nil?
              druid_prospects_all_30days = "#{number(value_all)}"
            end
          end
        end
      end      
      
      # Calculate 60-day trend on prospects_30days [ASSUMPTION: all data points are 1 day apart]
      trendline_slope = 0
      trendline_slope_text = ''
      trend_level = 0
      data = ConversionsForAgent.where(property: cfa.property, agent: cfa.agent).where("date <= ?", @date).where.not(prospects_30days: nil).order("date DESC").first(60)
      if data.count == 60 && cfa.units > 0
        values = data.reverse_each.map{ |e| (e.prospects_30days / cfa.units) * 100.0 }
        trend_line_data = values.trend_line()
        trendline_slope = trend_line_data[:slope]
        # puts "property: #{data[0].property.code}, 60-day percentage trendline slope: #{slope}"
      end

      {
        :order => 2,
        :id => cfa.id,
        :property => cfa.property,
        :agent => cfa.agent,
        :agent_level => agent_level,
        :units => cfa.units,
        :occupancy_average_daily => occupancy_average_daily,
        :occupancy_level => occupancy_level,
        :trending_average_daily => trending_average_daily,
        :trending_level => trending_level,
        :avg_renewal => metrics[:avg_renewal],
        :avg_decline => metrics[:avg_decline],
        :avg_conversion => metrics[:avg_conversion],
        :avg_closing => metrics[:avg_closing],
        :num_of_leads_needed => metrics[:num_of_leads_needed],
        :prospects_30days => cfa.prospects_30days,
        :druid_prospects_30days => druid_prospects_30days,
        :druid_prospects_all_30days => druid_prospects_all_30days,
        :prospects_30days_delta => prospects_30days_delta,
        :alert => metrics[:alert],
        :ideal_leads => metrics[:ideal_leads],
        :blueshift_leads => metrics[:blueshift_leads],
        :trendline_slope => trendline_slope,
        :trendline_slope_text => trendline_slope_text,
        :trend_level => trend_level
      }
    end 
    
    # Push Portfolio data
    if @property_id.nil?
      if @team_code == 'All'
        table_data.push(portfolio_data(table_data))
        @team_codes.each do |team_code|
          unless team_code == 'All'
            table_data.push(team_data(team_code, table_data))
          end
        end
      else
        table_data.push(team_data(@team_code, table_data))
      end
    end
    
    return table_data
  end

  def portfolio_data(table_data)
    portfolio_units = 0
    portfolio_num_of_leads_needed = 0
    portfolio_prospects_30days = 0
    portfolio_druid_prospects_30days = 0
    portfolio_druid_prospects_all_30days = 0
    portfolio_prospects_30days_delta = 0
    table_data.each do |row|
      portfolio_units += row[:units].to_i
      portfolio_num_of_leads_needed += row[:num_of_leads_needed].to_i
      portfolio_prospects_30days += row[:prospects_30days].to_i
      portfolio_druid_prospects_30days += row[:druid_prospects_30days].to_i
      portfolio_druid_prospects_all_30days += row[:druid_prospects_all_30days].to_i
      portfolio_prospects_30days_delta += row[:prospects_30days_delta].to_i
    end

    if portfolio_prospects_30days_delta > 0
      portfolio_prospects_30days_delta_string = "+#{portfolio_prospects_30days_delta}"
    else
      portfolio_prospects_30days_delta_string = portfolio_prospects_30days_delta.to_s
    end

    {
      :id => 'portfolio',
      :order => -100,
      :property => 'Portfolio',
      :agent => 'Portfolio',
      :agent_level => 0,
      :units => portfolio_units,
      :num_of_leads_needed => portfolio_num_of_leads_needed,
      :prospects_30days => portfolio_prospects_30days,
      :druid_prospects_30days => portfolio_druid_prospects_30days,
      :druid_prospects_all_30days => portfolio_druid_prospects_30days,
      :prospects_30days_delta => portfolio_prospects_30days_delta_string
    }
  end

  def team_data(team_code, table_data)
    team = Property.where(code: team_code).first
    team_property_codes = Property.properties.where(active: true, team_id: team).pluck('code')

    team_units = 0
    team_num_of_leads_needed = 0
    team_prospects_30days = 0
    team_druid_prospects_30days = 0
    team_druid_prospects_all_30days = 0
    team_prospects_30days_delta = 0
    table_data.each do |row|
      if team_property_codes.include?(row[:agent])
        team_units += row[:units].to_i
        team_num_of_leads_needed += row[:num_of_leads_needed].to_i
        team_prospects_30days += row[:prospects_30days].to_i
        team_druid_prospects_30days += row[:druid_prospects_30days].to_i
        team_druid_prospects_all_30days += row[:druid_prospects_all_30days].to_i
        team_prospects_30days_delta += row[:prospects_30days_delta].to_i
      end
    end

    if team_prospects_30days_delta > 0
      team_prospects_30days_delta_string = "+#{team_prospects_30days_delta}"
    else
      team_prospects_30days_delta_string = team_prospects_30days_delta.to_s
    end

    {
      :id => 'team',
      :team_id => team.id,
      :order => -99,
      :property => team_code,
      :agent => team_code,
      :agent_level => 0,
      :units => team_units,
      :num_of_leads_needed => team_num_of_leads_needed,
      :prospects_30days => team_prospects_30days,
      :druid_prospects_30days => team_druid_prospects_30days,
      :druid_prospects_all_30days => team_druid_prospects_all_30days,
      :prospects_30days_delta => team_prospects_30days_delta_string
    }
  end

  def create_table_data
    table_data = @data.collect do |row|
      if row[:druid_prospects_30days] == ''
        row_druid_prospects_30days = ''
      else
        if row[:druid_prospects_all_30days] == ''
          row_druid_prospects_30days = "#{row[:druid_prospects_30days]} (#{row[:prospects_30days_delta]})"
        else
          row_druid_prospects_30days = "#{row[:druid_prospects_30days]} (#{row[:prospects_30days_delta]}) / #{row[:druid_prospects_all_30days]}"
        end
      end

      trendline_slope_text = row[:trendline_slope_text]
      trendline_slope = row[:trendline_slope]
      if trendline_slope.nil?
        trendline_slope_text = ''
        trendline_slope = 0
      end

      if trendline_slope > 0
        trendline_slope_text = '▲'
        if trendline_slope > 0.20
          trend_level = 1
        else
          trend_level = 2
        end
      elsif trendline_slope < 0
        trendline_slope_text = '▼'
        if trendline_slope >= -0.20
          trend_level = 3
        else
          trend_level = 6
        end
      end

      if row[:avg_renewal].nil?
        avg_renewal = ''
      else
        avg_renewal = percent(row[:avg_renewal] * 100)
      end
      if row[:avg_decline].nil?
        avg_decline = ''
      else
        avg_decline = percent(row[:avg_decline] * 100)
      end
      if row[:avg_conversion].nil?
        avg_conversion = ''
      else
        avg_conversion = percent(row[:avg_conversion] * 100)
      end
      if row[:avg_closing].nil?
        avg_closing = ''
      else
        avg_closing = percent(row[:avg_closing] * 100)
      end

      if row[:team_id].nil?
        team_html = ''
      else
        team_html = "<input class='team_id' type='hidden' value='#{row[:team_id]}'>"
      end

      [
        "<input class='conversions_for_agents_id' type='hidden' value='#{row[:id]}'><input class='date' type='hidden' value='#{@date}'>#{team_html}<span class='level-#{row[:agent_level]}'>#{row[:agent]}</span>",
        "<span>#{number(row[:units])}</span>",
        "<span class='level-#{row[:occupancy_level]}'>#{percent(row[:occupancy_average_daily])}</span>",
        "<span class='level-#{row[:trending_level]}'>#{percent(row[:trending_average_daily])}</span>",
        "<span class='level-#{avg_renewal_level(row[:avg_renewal])}'>#{avg_renewal}</span>",
        "<span>#{avg_decline}</span>",
        "<span class='level-#{avg_conversion_level(row[:avg_conversion])}'>#{avg_conversion}</span>",
        "<span class='level-#{avg_closing_level(row[:avg_closing])}'>#{avg_closing}</span>",
        "<span>#{number(row[:num_of_leads_needed])}</span>",
        "<span class='level-#{trend_level}'>#{trendline_slope_text}</span> <span data-metric='prospects_30days' class='level-#{leads_reported_level(row[:num_of_leads_needed], row[:prospects_30days])}'>#{number(row[:prospects_30days])}</span>",
        "<span>#{row_druid_prospects_30days}</span>",
        "<span>#{row[:alert]}</span>",
        "<span class='level-#{ideal_leads_level(row[:ideal_leads], row[:prospects_30days])}'>#{number(row[:ideal_leads])}</span>",
        "<span class='level-#{blueshift_leads_level(row[:blueshift_leads], row[:prospects_30days])}'>#{number(row[:blueshift_leads])}</span>"       
      ]
    end    
    
    return table_data
  end
  
  def number(value)
    number_with_precision(value, precision: 0, strip_insignificant_zeros: true)  
  end

  def money(value)
    number_with_precision(value, precision: 2, strip_insignificant_zeros: false)  
  end
  
  def percent(value)
    number_to_percentage(value, precision: 0, strip_insignificant_zeros: true)
  end

  def avg_renewal_level(value)
    unless value.nil?
      percentage_value = value * 100
      return 1 if percentage_value >= 60
      return 2 if percentage_value > 50
      return 3 if percentage_value >= 40
      return 6 if percentage_value < 40
    end
    return nil
  end

  def avg_conversion_level(value)
    unless value.nil?
      percentage_value = value * 100
      return 1 if percentage_value >= 40
      return 2 if percentage_value > 38
      return 3 if percentage_value >= 29
      return 6 if percentage_value < 29
    end
    return nil
  end

  def avg_closing_level(value)
    unless value.nil?
      percentage_value = value * 100
      return 1 if percentage_value >= 40
      return 2 if percentage_value > 38
      return 3 if percentage_value >= 29
      return 6 if percentage_value < 29
    end
    return nil
  end

  def leads_reported_level(leads_needed, leads_reported)
    unless leads_needed.nil? || leads_reported.nil?
      return 1 if leads_reported > leads_needed
      return 2 if leads_reported >= leads_needed * 0.9
      return 3 if leads_reported >= leads_needed * 0.8
      return 6 if leads_reported < leads_needed * 0.8
    end
    return nil
  end

  def ideal_leads_level(ideal_leads, leads_reported)
    unless ideal_leads.nil? || leads_reported.nil?
      return 1 if ideal_leads < leads_reported
      return 3 if ideal_leads > leads_reported
    end
    return nil
  end

  def blueshift_leads_level(blueshift_leads, leads_reported)
    unless blueshift_leads.nil? || leads_reported.nil?
      return 1 if blueshift_leads < leads_reported
      return 3 if blueshift_leads > leads_reported
    end
    return nil
  end

  def get_sort_column
    columns = %w[agent 
      units
      occupancy_average_daily
      trending_average_daily
      avg_renewal
      avg_decline
      avg_conversion 
      avg_closing
      num_of_leads_needed
      prospects_30days
      druid_leads
      alert
      ideal_leads
      blueshift_leads
    ]
      
    unless params["order"].nil? || params["order"]["0"]["column"].nil?
      return columns[params["order"]["0"]["column"].to_i]
    end
      
    return columns[0]
  end

  def sort_direction
    unless params["order"].nil? || params["order"]["0"]["dir"].nil?
      return params["order"]["0"]["dir"] 
    end

    return 'asc'
  end  
  
  def set_ordering
    sort_column = get_sort_column
    
    if sort_column == "agent"
      # @data = @data.sort_by { |row| row[:agent] }
      @data = @data.sort_by { |row| row[:order].to_s + row[:agent].to_s }
    elsif sort_column == "units"
      @data = @data.sort_by { |row| row[:units].to_i }
    elsif sort_column == "occupancy_average_daily"
      @data = @data.sort_by { |row| row[:occupancy_average_daily].to_i }
    elsif sort_column == "trending_average_daily"
      @data = @data.sort_by { |row| row[:trending_average_daily].to_i }
    elsif sort_column == "avg_renewal"
      @data = @data.sort_by { |row| row[:avg_renewal].to_f }
    elsif sort_column == "avg_decline"
      @data = @data.sort_by { |row| row[:avg_decline].to_f }
    elsif sort_column == "avg_conversion"
      @data = @data.sort_by { |row| row[:avg_conversion].to_f }
    elsif sort_column == "avg_closing"
      @data = @data.sort_by { |row| row[:avg_closing].to_f }
    elsif sort_column == "num_of_leads_needed"
      @data = @data.sort_by { |row| row[:num_of_leads_needed].to_i }
    elsif sort_column == "prospects_30days"
      @data = @data.sort_by { |row| row[:num_of_leads_needed].to_i - row[:prospects_30days].to_i }
    elsif sort_column == "druid_leads"
      @data = @data.sort_by { |row| row[:druid_prospects_30days].to_i }
    elsif sort_column == "alert"
      @data = @data.sort_by { |row| row[:alert].to_s }
    elsif sort_column == "ideal_leads"
      @data = @data.sort_by { |row| row[:ideal_leads].to_i }
    elsif sort_column == "blueshift_leads"
      @data = @data.sort_by { |row| row[:blueshift_leads].to_i }
    else
      @data = @data.sort_by { |row| row[:agent].to_s }
    end

    if sort_direction == "desc"
      if sort_column == "agent"
        @data = @data.sort_by { |row| row[:order].to_i + (-1 * row[:agent_level].to_i) }
      else      
        @data = @data.reverse
      end
      
    end 
  end


end
