class UnitTypeRentHistoryController < ApplicationController
  include ActionView::Helpers::NumberHelper
  
  # GET /unit_type_rent_history?rent_change_reason_id={id}
  # GET /unit_type_rent_history.json?rent_change_reason_id={id}
  def show
    @rent_change_reason_id = params[:rent_change_reason_id]
    @rent_change_reason = RentChangeReason.find(@rent_change_reason_id)
    @unit_type_code = @rent_change_reason.unit_type_code
    unless @rent_change_reason.num_of_units.nil?
      @num_of_units = " (#{number(@rent_change_reason.num_of_units)})"
    else 
      @num_of_units = ""
    end 
    @property = @rent_change_reason.property
    @date = @rent_change_reason.date
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
    
    rent_change_reasons_unsorted = RentChangeReason.where(property: @property, unit_type_code: @unit_type_code).where("date >= ?", @date - 365.days)
    @rent_change_reasons = rent_change_reasons_unsorted.sort {|a,b| b.date <=> a.date}

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
      [
        "<input class='rent_change_reason_id' type='hidden' value='#{rcr.id}'><span>#{formatted_date(rcr.date)}</span>",
        "<span>$#{money(rcr.old_market_rent)}</span>",
        "<span>$#{money(rcr.new_rent)}</span>",
        "<span class='level-#{rcr.change_level}'>#{percent(rcr.percent_change)}</span>", 
        "<span class='level-#{rcr.change_level}'>#{number(rcr.change_amount)}</span>", 
        "<span>#{rcr.trigger}</span>"
      ]
    end    
    
    return table_data
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

  def formatted_date(date)
    if date.present?
      return date.strftime("%m/%d/%Y")
    else
      return nil
    end
  end

end
