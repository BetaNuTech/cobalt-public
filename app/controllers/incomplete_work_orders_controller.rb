class IncompleteWorkOrdersController < ApplicationController
  include ActionView::Helpers::NumberHelper
  include ApplicationHelper
  include ActionView::Helpers::OutputSafetyHelper
  
  # GET /incomplete_work_orders/
  # GET /incomplete_work_orders.json/
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
      @incomplete_work_orders = IncompleteWorkOrder.where("call_date <= ? AND latest_import_date >= ?", @date, @date).order("call_date ASC")
    elsif @property.type == 'Team'
      team_property_ids = Property.where(active: true, team_id: @property_id).pluck('id')
      team_property_ids.append(@team_id)
      @incomplete_work_orders = IncompleteWorkOrder.where(property: team_property_ids).where("call_date <= ? AND latest_import_date >= ?", @date, @date).order("call_date ASC")
    else
      @incomplete_work_orders = IncompleteWorkOrder.where(property: @property).where("call_date <= ? AND latest_import_date >= ?", @date, @date).order("call_date ASC")
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
    data = @incomplete_work_orders.collect do |wo|
      color_code_level = 0
      if wo.call_date < Date.today - 10.days
        color_code_level = 6
      elsif wo.call_date < Date.today - 5.days
        color_code_level = 3
      end

      compliance_issue_exists = false
      if wo.reason_incomplete.nil? || wo.reason_incomplete.strip.empty?
        compliance_issue_exists = true
      end

      {
        :id => wo.id,
        :call_date => wo.call_date,
        :update_date => wo.update_date,
        :work_order => wo.work_order,
        :unit => wo.unit,
        :brief_desc => wo.brief_desc,
        :reason_incomplete => wo.reason_incomplete,
        :color_code_level => color_code_level,
        :compliance_issue_exists => compliance_issue_exists
      }
    end    
    
    return data
  end
  
  def create_table_data
    table_data = @data.collect do |wo| 
      # Check for Compliance Issues
      compliance_html = ''
      if wo[:compliance_issue_exists]
        svg_link = "<svg class=\"incomplete_work_orders_svg_exclamation_mark_triangle\">#{show_svg('exclamationmark.triangle.svg')}</svg>"
        compliance_html = "<span class='incomplete_work_orders_compliance_issue'>#{svg_link}</span>"
      end

      [
        "<input class='incomplete_work_order_id' type='hidden' value='#{wo[:id]}'><input class='property_id' type='hidden' value='#{@property_id}'><input class='date' type='hidden' value='#{@date}'>#{compliance_html}<span class='level-#{wo[:color_code_level]}'>#{wo[:call_date]}</span>",
        "<span class='level-#{wo[:color_code_level]}'>#{wo[:update_date]}</span>",
        "<span class='level-#{wo[:color_code_level]}'>#{wo[:work_order]}</span>",
        "<span class='level-#{wo[:color_code_level]}'>#{wo[:unit]}</span>",
        "<span class='level-#{wo[:color_code_level]}'>#{wo[:brief_desc]}</span>", 
        "<span class='level-#{wo[:color_code_level]}'>#{wo[:reason_incomplete]}</span>"
      ]
    end    
    
    return table_data
  end

  def get_sort_column
    columns = %w[call_date 
      update_date
      work_order
      unit
      brief_desc
      reason_incomplete
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
    
    if sort_column == 'call_date'
      @data = @data.sort_by { |row| row[:call_date]  }
    elsif sort_column == 'update_date'
      @data = @data.sort_by { |row| row[:update_date]  }
    elsif sort_column == 'work_order'
      @data = @data.sort_by { |row| row[:work_order]  }
    elsif sort_column == 'unit'
      @data = @data.sort_by { |row| row[:unit]  }
    elsif sort_column == 'brief_desc'
      @data = @data.sort_by { |row| row[:brief_desc]  }
    elsif sort_column == 'reason_incomplete'
      @data = @data.sort_by { |row| row[:reason_incomplete]  }
    else
      @data = @data.sort_by { |row| row[:call_date]  }
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
