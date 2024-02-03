class CollectionsNonEvictionPast20DetailsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  
  # GET /collections_non_eviction_past20_details/
  # GET /collections_non_eviction_past20_details.json/
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
      @collection_details = CollectionsNonEvictionPast20Detail.where(date: @date).order("property_id ASC")
    elsif @property.type == 'Team'
      team_property_ids = Property.where(active: true, team_id: @property_id).pluck('id')
      @collection_details = CollectionsNonEvictionPast20Detail.where(date: @date, property: team_property_ids).order("property_id ASC")
    else
      @collection_details = CollectionsNonEvictionPast20Detail.where(date: @date, property: @property_id).order("property_id ASC")
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
    data = @collection_details.collect do |detail|
      {
        :id => detail.id,
        :property_id => detail.property_id,
        :property_code => detail.property.code,
        :yardi_code => detail.yardi_code,
        :tenant => detail.tenant,
        :unit => detail.unit,
        :balance => detail.balance
      }
    end    
    
    return data
  end
  
  def create_table_data
    table_data = @data.collect do |detail| 
      [
        "<input class='collections_non_eviction_past20_detail_id' type='hidden' value='#{detail[:id]}'><input class='property_id' type='hidden' value='#{detail[:property_id]}'><input class='date' type='hidden' value='#{@date}'><span>#{detail[:property_code]}</span>",
        "<span>#{detail[:yardi_code]}</span>",
        "<span>#{detail[:tenant]}</span>",
        "<span>#{detail[:unit]}</span>",
        "<span>$#{money(detail[:balance])}</span>"
      ]
    end    
    
    return table_data
  end

  def get_sort_column
    columns = %w[property_code 
      yardi_code
      tenant
      unit
      balance
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
    elsif sort_column == 'balance'
      @data = @data.sort_by { |row| row[:balance].to_i }
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
