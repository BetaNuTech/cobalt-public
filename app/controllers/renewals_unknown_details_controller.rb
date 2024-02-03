class RenewalsUnknownDetailsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  
  # GET /renewals_unknown_details/
  # GET /renewals_unknown_details.json/
  def show
    @date = params[:date]
    @property_id = params[:property_id]
    @property = Property.find(@property_id)
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
    
    if @property.code.downcase == 'portfolio'
      @renewals_unknown_details = RenewalsUnknownDetail.where(date: @date).order("property_id ASC")
    elsif @property.type == 'Team'
      team_property_ids = Property.where(active: true, team_id: @property_id).pluck('id')
      @renewals_unknown_details = RenewalsUnknownDetail.where(date: @date, property: team_property_ids).order("property_id ASC")
    else
      @renewals_unknown_details = RenewalsUnknownDetail.where(date: @date, property: @property_id).order("property_id ASC")
    end
    
    @data = create_data
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

  def create_data
    data = @renewals_unknown_details.collect do |unknown|
      {
        :id => unknown.id,
        :property_id => unknown.property_id,
        :property_code => unknown.property.code,
        :yardi_code => unknown.yardi_code,
        :tenant => unknown.tenant,
        :unit => unknown.unit
      }
    end    
    
    return data
  end
  
  def create_table_data
    table_data = @data.collect do |unknown| 
      [
        "<input class='renewals_unknown_detail_id' type='hidden' value='#{unknown[:id]}'><input class='property_id' type='hidden' value='#{unknown[:property_id]}'><input class='date' type='hidden' value='#{@date}'><span>#{unknown[:property_code]}</span>",
        "<span>#{unknown[:yardi_code]}</span>",
        "<span>#{unknown[:tenant]}</span>",
        "<span>#{unknown[:unit]}</span>"
      ]
    end    
    
    return table_data
  end

  def get_sort_column
    columns = %w[property_code 
      yardi_code
      tenant
      unit
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
    
    if sort_column == 'property_code'
      @data = @data.sort_by { |row| row[:property_code]  }
    elsif sort_column == 'yardi_code'
      @data = @data.sort_by { |row| row[:yardi_code]  }
    elsif sort_column == 'tenant'
      @data = @data.sort_by { |row| row[:tenant]  }
    elsif sort_column == 'unit'
      @data = @data.sort_by { |row| row[:unit]  }
    else
      @data = @data.sort_by { |row| row[:property_id]  }
    end

    if sort_direction == "desc"     
        @data = @data.reverse      
    end
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
