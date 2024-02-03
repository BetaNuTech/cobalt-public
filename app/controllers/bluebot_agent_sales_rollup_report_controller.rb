class BluebotAgentSalesRollupReportController < ApplicationController
  include ActionView::Helpers::NumberHelper
  
  # GET /bluebot_agent_sales_rollup_report?property_id=<id>
  # GET /bluebot_agent_sales_rollup_report.json?property_id=<id>
  # params[:bluebot_rollup_report_form][:end_month] - required
  # (optional) params[:reversed] - To reverse order of months
  def show

    @property_name = ''

    @property_id = params[:property_id]

    if @property_id.nil?
      return
    end

    @property = Property.find(@property_id)

    if @property.nil?
      return
    end

    if @property.full_name.nil?
      @property_name = @property.code
    else
      @property_name = @property.full_name
    end

    @reversed = params[:reversed] ? true : false

    end_date = params[:bluebot_rollup_report_form] ? Date.parse(params[:bluebot_rollup_report_form][:end_month].to_s) : Date.today
    @report_form = BluebotRollupReportForm.new({end_month: end_date })

    if @reversed
      @dates = (1..12).to_a.map{ |d| (end_date + 1.day - d.months).end_of_month }
      @next_day_dates = (0..11).to_a.map{ |d| (end_date + 1.day - d.months).beginning_of_month }
      @date_names = @dates.collect do |d|
        d.strftime("%b")
      end
    else
      @dates = (1..12).to_a.reverse.map{ |d| (end_date + 1.day - d.months).end_of_month }
      @next_day_dates = (0..11).to_a.reverse.map{ |d| (end_date + 1.day - d.months).beginning_of_month }
      @date_names = @dates.collect do |d|
        d.strftime("%b")
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

    if @reversed
      @agents = SalesForAgent.where(property: @property, date: @dates[0])
    else
      @agents = SalesForAgent.where(property: @property, date: @dates[11])
    end

    if @agents.nil?
      render json: nil
      return
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
    data = @agents.collect do |sfa|
      c0 = SalesForAgent.where(property: @property, agent: sfa.agent, date: @dates[0]).first
      c1 = SalesForAgent.where(property: @property, agent: sfa.agent, date: @dates[1]).first
      c2 = SalesForAgent.where(property: @property, agent: sfa.agent, date: @dates[2]).first
      c3 = SalesForAgent.where(property: @property, agent: sfa.agent, date: @dates[3]).first
      c4 = SalesForAgent.where(property: @property, agent: sfa.agent, date: @dates[4]).first
      c5 = SalesForAgent.where(property: @property, agent: sfa.agent, date: @dates[5]).first
      c6 = SalesForAgent.where(property: @property, agent: sfa.agent, date: @dates[6]).first
      c7 = SalesForAgent.where(property: @property, agent: sfa.agent, date: @dates[7]).first
      c8 = SalesForAgent.where(property: @property, agent: sfa.agent, date: @dates[8]).first
      c9 = SalesForAgent.where(property: @property, agent: sfa.agent, date: @dates[9]).first
      c10 = SalesForAgent.where(property: @property, agent: sfa.agent, date: @dates[10]).first
      c11 = SalesForAgent.where(property: @property, agent: sfa.agent, date: @dates[11]).first

      c0_n = SalesForAgent.where(property: @property, agent: sfa.agent, date: @next_day_dates[0]).first
      c1_n = SalesForAgent.where(property: @property, agent: sfa.agent, date: @next_day_dates[1]).first
      c2_n = SalesForAgent.where(property: @property, agent: sfa.agent, date: @next_day_dates[2]).first
      c3_n = SalesForAgent.where(property: @property, agent: sfa.agent, date: @next_day_dates[3]).first
      c4_n = SalesForAgent.where(property: @property, agent: sfa.agent, date: @next_day_dates[4]).first
      c5_n = SalesForAgent.where(property: @property, agent: sfa.agent, date: @next_day_dates[5]).first
      c6_n = SalesForAgent.where(property: @property, agent: sfa.agent, date: @next_day_dates[6]).first
      c7_n = SalesForAgent.where(property: @property, agent: sfa.agent, date: @next_day_dates[7]).first
      c8_n = SalesForAgent.where(property: @property, agent: sfa.agent, date: @next_day_dates[8]).first
      c9_n = SalesForAgent.where(property: @property, agent: sfa.agent, date: @next_day_dates[9]).first
      c10_n = SalesForAgent.where(property: @property, agent: sfa.agent, date: @next_day_dates[10]).first
      c11_n = SalesForAgent.where(property: @property, agent: sfa.agent, date: @next_day_dates[11]).first

      @year_sales = 0
      @year_goal = 0

      c0_data = c0.nil? ? {:percentage => -999} : c_data(c0.sales, c0.goal, c0_n)
      c1_data = c1.nil? ? {:percentage => -999} : c_data(c1.sales, c1.goal, c1_n)
      c2_data = c2.nil? ? {:percentage => -999} : c_data(c2.sales, c2.goal, c2_n)
      c3_data = c3.nil? ? {:percentage => -999} : c_data(c3.sales, c3.goal, c3_n)
      c4_data = c4.nil? ? {:percentage => -999} : c_data(c4.sales, c4.goal, c4_n)
      c5_data = c5.nil? ? {:percentage => -999} : c_data(c5.sales, c5.goal, c5_n)
      c6_data = c6.nil? ? {:percentage => -999} : c_data(c6.sales, c6.goal, c6_n)
      c7_data = c7.nil? ? {:percentage => -999} : c_data(c7.sales, c7.goal, c7_n)
      c8_data = c8.nil? ? {:percentage => -999} : c_data(c8.sales, c8.goal, c8_n)
      c9_data = c9.nil? ? {:percentage => -999} : c_data(c9.sales, c9.goal, c9_n)
      c10_data = c10.nil? ? {:percentage => -999} : c_data(c10.sales, c10.goal, c10_n)
      c11_data = c11.nil? ? {:percentage => -999} : c_data(c11.sales, c11.goal, c11_n)

      if @year_goal <= 0
        if @year_sales >= @year_goal # attained >= total_goal, then (ABS(A-T)+1)/1
          @year_sales = (@year_sales - @year_goal).abs + 1
          @year_goal = 1
          percent_of_year_goal_num = @year_sales.to_f / @year_goal.to_f * 100.0
        else # attained < total_goal, then 0/ABS(T-A)
          @year_sales = 0
          @year_goal = (@year_goal - @year_sales).abs
          percent_of_year_goal_num = @year_sales.to_f / @year_goal.to_f * 100.0    
        end
      else # total lease goal > 0
        percent_of_year_goal_num = @year_sales.to_f / @year_goal.to_f * 100.0
      end

      percent_of_year_goal_num = percent_of_year_goal_num > 100 ? 100 : percent_of_year_goal_num


      year_heart = percent_of_year_goal_num >= 100 ? '♥&#xFE0E;' : ''

      {
        :agent => sfa.agent,
        :c0_data => c0_data,
        :c1_data => c1_data,
        :c2_data => c2_data,
        :c3_data => c3_data,
        :c4_data => c4_data,
        :c5_data => c5_data,
        :c6_data => c6_data,
        :c7_data => c7_data,
        :c8_data => c8_data,
        :c9_data => c9_data,
        :c10_data => c10_data,
        :c11_data => c11_data,
        :percent_of_year_goal_num => percent_of_year_goal_num,
        :year_sales => @year_sales,
        :year_goal => @year_goal,
        :year_heart => year_heart
      }
    end    
    
    return data
  end

  def create_table_data
    table_data = @data.collect do |row| 
      col0 = row[:c0_data][:sales].nil? ? 'NA' : "#{'%0.f' % row[:c0_data][:sales]}/#{'%0.f' % row[:c0_data][:goal]}#{row[:c0_data][:heart]}"
      col1 = row[:c1_data][:sales].nil? ? 'NA' : "#{'%0.f' % row[:c1_data][:sales]}/#{'%0.f' % row[:c1_data][:goal]}#{row[:c1_data][:heart]}"
      col2 = row[:c2_data][:sales].nil? ? 'NA' : "#{'%0.f' % row[:c2_data][:sales]}/#{'%0.f' % row[:c2_data][:goal]}#{row[:c2_data][:heart]}"
      col3 = row[:c3_data][:sales].nil? ? 'NA' : "#{'%0.f' % row[:c3_data][:sales]}/#{'%0.f' % row[:c3_data][:goal]}#{row[:c3_data][:heart]}"
      col4 = row[:c4_data][:sales].nil? ? 'NA' : "#{'%0.f' % row[:c4_data][:sales]}/#{'%0.f' % row[:c4_data][:goal]}#{row[:c4_data][:heart]}"
      col5 = row[:c5_data][:sales].nil? ? 'NA' : "#{'%0.f' % row[:c5_data][:sales]}/#{'%0.f' % row[:c5_data][:goal]}#{row[:c5_data][:heart]}"
      col6 = row[:c6_data][:sales].nil? ? 'NA' : "#{'%0.f' % row[:c6_data][:sales]}/#{'%0.f' % row[:c6_data][:goal]}#{row[:c6_data][:heart]}"
      col7 = row[:c7_data][:sales].nil? ? 'NA' : "#{'%0.f' % row[:c7_data][:sales]}/#{'%0.f' % row[:c7_data][:goal]}#{row[:c7_data][:heart]}"
      col8 = row[:c8_data][:sales].nil? ? 'NA' : "#{'%0.f' % row[:c8_data][:sales]}/#{'%0.f' % row[:c8_data][:goal]}#{row[:c8_data][:heart]}"
      col9 = row[:c9_data][:sales].nil? ? 'NA' : "#{'%0.f' % row[:c9_data][:sales]}/#{'%0.f' % row[:c9_data][:goal]}#{row[:c9_data][:heart]}"
      col10 = row[:c10_data][:sales].nil? ? 'NA' : "#{'%0.f' % row[:c10_data][:sales]}/#{'%0.f' % row[:c10_data][:goal]}#{row[:c10_data][:heart]}"
      col11 = row[:c11_data][:sales].nil? ? 'NA' : "#{'%0.f' % row[:c11_data][:sales]}/#{'%0.f' % row[:c11_data][:goal]}#{row[:c11_data][:heart]}"

      [        
        "<span>#{row[:agent]}</span>",
        "<span>#{col0}</span>",
        "<span>#{col1}</span>",
        "<span>#{col2}</span>",
        "<span>#{col3}</span>",
        "<span>#{col4}</span>",
        "<span>#{col5}</span>",
        "<span>#{col6}</span>",
        "<span>#{col7}</span>",
        "<span>#{col8}</span>",
        "<span>#{col9}</span>",
        "<span>#{col10}</span>",
        "<span>#{col11}</span>",
        "<div class=\"w3-border\" style=\"width:80px;\"><div class=\"w3-white\" style=\"height:20px;width:#{'%0.f' % row[:percent_of_year_goal_num]}%\"></div></div>",
        "<span>#{'%0.f' % row[:year_sales]}/#{'%0.f' % row[:year_goal]}#{row[:year_heart]}</span>"
      ]
    end

    return table_data
  end


  def c_data(sales, goal, next_day_metric)
    unless sales.nil?
      if !next_day_metric.nil? && !next_day_metric.sales.nil?
        sales += next_day_metric.sales
      end
      percentage = SalesForAgent.calc_percentage(sales, goal)
      @year_sales += sales
      @year_goal += goal
      heart = percentage >= 100 ? '♥&#xFE0E;' : ''
      # return "#{'%0.f' % leases}/#{'%0.f' % goal}#{heart}"
      return {:sales => sales, :goal => goal, :heart => heart, :percentage => percentage}
    end
      
    return {:percentage => -999}
  end

  def get_sort_column
    columns = %w[agent 
      c0_data
      c1_data
      c2_data
      c3_data
      c4_data
      c5_data
      c6_data
      c7_data
      c8_data
      c9_data
      c10_data
      c11_data
      percent_of_year_goal_num
      percent_of_year_goal_num
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
    
    if sort_column == 'agent'
      @data = @data.sort_by { |row| row[:agent] }
    elsif sort_column == 'c0_data'
      @data = @data.sort_by { |row| row[:c0_data][:percentage] }
    elsif sort_column == 'c1_data'
      @data = @data.sort_by { |row| row[:c1_data][:percentage] }
    elsif sort_column == 'c2_data'
      @data = @data.sort_by { |row| row[:c2_data][:percentage] }
    elsif sort_column == 'c3_data'
      @data = @data.sort_by { |row| row[:c3_data][:percentage] }
    elsif sort_column == 'c4_data'
      @data = @data.sort_by { |row| row[:c4_data][:percentage] }
    elsif sort_column == 'c5_data'
      @data = @data.sort_by { |row| row[:c5_data][:percentage] }
    elsif sort_column == 'c6_data'
      @data = @data.sort_by { |row| row[:c6_data][:percentage] }
    elsif sort_column == 'c7_data'
      @data = @data.sort_by { |row| row[:c7_data][:percentage] }
    elsif sort_column == 'c8_data'
      @data = @data.sort_by { |row| row[:c8_data][:percentage] }
    elsif sort_column == 'c9_data'
      @data = @data.sort_by { |row| row[:c9_data][:percentage] }
    elsif sort_column == 'c10_data'
      @data = @data.sort_by { |row| row[:c10_data][:percentage] }
    elsif sort_column == 'c11_data'
      @data = @data.sort_by { |row| row[:c11_data][:percentage] }
    elsif sort_column == 'percent_of_year_goal_num'
      @data = @data.sort_by { |row| row[:percent_of_year_goal_num] }
    else
      @data = @data.sort_by { |row| row[:agent] }
    end

    if sort_direction == "desc"     
        @data = @data.reverse      
    end
  end
  
  def number(value)
    number_with_precision(value, precision: 0, strip_insignificant_zeros: true)  
  end

end
