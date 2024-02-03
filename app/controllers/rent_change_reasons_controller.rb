class RentChangeReasonsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  
  # GET /rent_change_reasons/:metric_id
  # GET /rent_change_reasons/:metric_id.json
  def show
    @metric_id = params[:metric_id]
    @metric = Metric.find(@metric_id)
    @date = @metric.date
    @property = Property.find(@metric.property_id)
    @property_name = @property.full_name
    if @property_name.nil?
      @property_name = @property.code
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
    
    @rent_change_reasons = RentChangeReason.where(property: @property, date: @date).order("unit_type_code ASC")
    
    data_tables = create_data_tables
    render json: data_tables.as_json
  end
  
  def create_data_tables
    data_tables = {
         data: create_table_data
       }
       
    return data_tables    
  end
  
  def create_table_data
    table_data = @rent_change_reasons.collect do |rcr| 
      last_survey_days_ago = number(rcr.last_survey_days_ago).to_s
      unit_type = "#{number(rcr.unit_type_code)}"
      unless rcr.num_of_units.nil? || (!rcr.num_of_units.nil? && rcr.num_of_units == 0)
        unit_type = "#{number(rcr.unit_type_code)} (#{number(rcr.num_of_units)})"
      end
      if rcr.last_survey_days_ago.nil?
        last_survey_days_ago = ""
      elsif rcr.last_survey_days_ago > 365*50 # 50 years is long enough back
        last_survey_days_ago = "No survey done"
      end

      new_effective = 'No Data'
      market_rent = 'No Data'
      last_three_rent = 'No Data'
      if rcr.last_three_rent.present?
        last_three_rent = '$' + money(rcr.last_three_rent).to_s
      end
      # Search for the 1st digit, in unit_type
      bedroom_count = find_first_digit(unit_type)
      if bedroom_count > 0
        detail = AverageRentsBedroomDetail.where(property: @property, date: @date, num_of_bedrooms: bedroom_count).first
        if !detail.nil?
          new_effective = '$' + money(detail.net_effective_average_rent).to_s
          market_rent = '$' + money(detail.market_rent).to_s
        end
      end

      [
        "<input class='rent_change_reason_id' type='hidden' value='#{rcr.id}'><span data-unit-type-rent-history='show'>#{unit_type}</span>",
        "<span>$#{money(rcr.old_market_rent)}</span>",
        "<span>$#{money(rcr.new_rent)}</span>",
        "<span>#{new_effective}</span>",
        "<span>#{market_rent}</span>",
        "<span>#{last_three_rent}</span>",
        "<span class='level-#{rcr.change_level}'>#{percent(rcr.percent_change)}</span>", 
        "<span class='level-#{rcr.change_level}'>#{number(rcr.change_amount)}</span>", 
        "<span>#{rcr.trigger}</span>",
        "<span class='level-#{rcr.trend_30days_out_level}'>#{percent(rcr.average_daily_occupancy_trend_30days_out)}</span>",
        "<span class='level-#{rcr.trend_60days_out_level}'>#{percent(rcr.average_daily_occupancy_trend_60days_out)}</span>",
        "<span class='level-#{rcr.trend_90days_out_level}'>#{percent(rcr.average_daily_occupancy_trend_90days_out)}</span>",
        "<span>#{last_survey_days_ago}</span>",
        "<span>#{rcr.units_vacant_not_leased}</span>",
        "<span>#{rcr.units_on_notice_not_leased}</span>"
      ]
    end    
    
    return table_data
  end

  def find_first_digit(string)
    if !string.nil?
      return string[/\d/].to_i
    end

    return 0
  end
  
  def number(value)
    number_with_precision(value, precision: 1, strip_insignificant_zeros: true)  
  end

  def money(value)
    number_with_precision(value, precision: 2, strip_insignificant_zeros: false)  
  end
  
  def percent(value)
    number_to_percentage(value, precision: 1, strip_insignificant_zeros: true)
  end


end
