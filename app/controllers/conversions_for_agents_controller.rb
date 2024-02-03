class ConversionsForAgentsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  
  # GET /conversions_for_agents/:property_id:date
  # GET /conversions_for_agents/:property_id:date.json
  def show
    @property_id = params[:property_id]
    @date = params[:date]
    @property = Property.find(@property_id)
    @property_name = @property.full_name
    if @property_name.nil?
      @property_name = @property.code
    end

    @bluebot_agent_sales_rollup_report_link = view_context.link_to("View Bluebot Rollup for Agents", bluebot_agent_sales_rollup_report_path(property_id: @property_id), class: 'agent_sales_rollup_link', data: { turbolinks: false })

    respond_to do |format|
      format.html
      format.json do 
        render_datatables
      end
    end

  end
  
  private
  def render_datatables
    
    @conversions_for_agents = ConversionsForAgent.where(property: @property, date: @date, is_property_data: false).order("agent ASC")
    
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
    table_data = @conversions_for_agents.collect do |cfa| 
      [
        "<input class='conversions_for_agents_id' type='hidden' value='#{cfa.id}'><span>#{cfa.agent}</span>",
        "<span>#{number(cfa.prospects_30days)}</span>",
        "<span class='level-#{cfa.conversion_30days_level}'>#{number(cfa.conversion_30days)}%</span>",
        "<span class='level-#{cfa.close_30days_level}'>#{number(cfa.close_30days)}%</span>",
        "<span>#{number(cfa.prospects_180days)}</span>",
        "<span class='level-#{cfa.conversion_180days_level}'>#{number(cfa.conversion_180days)}%</span>",
        "<span class='level-#{cfa.close_180days_level}'>#{number(cfa.close_180days)}%</span>",
        "<span>#{number(cfa.prospects_365days)}</span>",
        "<span class='level-#{cfa.conversion_365days_level}'>#{number(cfa.conversion_365days)}%</span>",
        "<span class='level-#{cfa.close_365days_level}'>#{number(cfa.close_365days)}%</span>",
        "blank"
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


end
