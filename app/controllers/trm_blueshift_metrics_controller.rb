class TrmBlueshiftMetricsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  
  # GET /trm_blueshift_metrics?team_id={id}[&date=<date>]
  # GET /trm_blueshift_metrics.json?team_id={id}[&date=<date>]
  def show
    @team_id = params[:team_id]
    @team = Property.find(@team_id)  # Team is a type of property
    unless @team.nil?
      @team_name = @team.full_name
    else  
      @team_name = ""
    end
    if params[:date].present?
      @date = Date.strptime(params[:date], "%m/%d/%Y")
    else
      @date = Time.now.to_date
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
    
    if !@team.nil? && @team.code == Property.portfolio_code()
      @properties = Property.properties.where(active: true).order("code ASC")
    elsif !@team.nil?
      @properties = Property.properties.where(team_id: @team.id, active: true).order("code ASC")
    end
    
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
    if @properties.nil?
      return nil
    end
  

    table_data = @properties.collect do |prop| 

      if prop.trm_blue_shift_status == "required" 
        if can?(:create_trm_blue_shift, prop)
          property_name = view_context.link_to(prop.code, new_property_trm_blue_shift_path(property_id: prop.id) , class: 'flash flash_red', data: { turbolinks: false })
        else
          property_name = "<span class='flash flash_red'>#{prop.code}</span>"
        end
      elsif prop.trm_blue_shift_status == "pending"
        user_property = UserProperty.where(user: current_user, property: prop).first
        trm_blue_shift = prop.current_trm_blue_shift
        
        if prop.current_trm_blue_shift.present? and prop.current_trm_blue_shift.any_fix_by_date_expired? 
          css_class = "flash_row_red"
        # Has been viewed
        elsif user_property.present? and user_property.trm_blue_shift_status == "viewed"
          css_class = "blue"
        else
          css_class = "flash flash_blue"
        end
        
        if can?(:create_trm_blue_shift, prop)
          property_name = view_context.link_to(prop.code, property_trm_blue_shift_path(prop.id, trm_blue_shift), class: css_class, data: { turbolinks: false })
        else
          property_name = "<span class='#{css_class}'>#{prop.code}</span>"
        end

      else
        if can?(:create_trm_blue_shift, prop)
          property_name = view_context.link_to(prop.code, new_property_trm_blue_shift_path(property_id: prop.id), data: { turbolinks: false })
        else
          property_name = prop.code
        end        
      end

      latest_metric = Metric.where(property: prop, date: Date.today).first
      if latest_metric.nil?
        latest_metric = Metric.where(property: prop).where(main_metrics_received: true).order("date DESC").first
      end

      trigger_metrics = latest_metric.trm_blueshift_trigger_reasons()
      trigger_metrics_string = trigger_metrics.join("<br>")

      [
        "<input class='property_id' type='hidden' value='#{prop.id}'><input class='date' type='hidden' value='#{@date}'><span class='property_name'>#{property_name}</span>",
        "#{trigger_metrics_string}"
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


end
