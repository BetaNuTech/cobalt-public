class BluebotRollupReportController < ApplicationController
  include ActionView::Helpers::NumberHelper
  
  # GET /bluebot_rollup_report
  # GET /bluebot_rollup_report.json
  def show

    @end_date = params[:bluebot_rollup_report_form] ? Date.parse(params[:bluebot_rollup_report_form][:end_month].to_s) : (Date.today + 1.day - 1.month).end_of_month
    @report_form = BluebotRollupReportForm.new({end_month: @end_date })

    @dates = (1..14).to_a.reverse.map{ |d| (@end_date + 1.day - d.months).end_of_month }
    @next_day_dates = (0..13).to_a.reverse.map{ |d| (@end_date + 1.day - d.months).beginning_of_month }
    @dates.append(Date.today) # For current month, current day data
    @date_names = @dates.collect do |d|
      d.strftime("%b")
    end

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

    set_quarter_names()
    
    respond_to do |format|
      format.html
      format.json do 
        render_datatables
      end
    end

  end
  
  private
  def render_datatables
    
    if @team_selected
      @properties = Property.where(active: true, team_id: @team_selected.id).order("code ASC")
      @properties.unshift(@team_selected)
    else
      @properties = Property.where(active: true).order("code ASC")
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
    data = @properties.collect do |p|
      all_months = Metric.where(property: p, date: @dates).order("date ASC")
      m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, mc = nil
      all_months.each do |month|
        case month.date
        when @dates[0]
          m0 = month
        when @dates[1]
          m1 = month
        when @dates[2]
          m2 = month
        when @dates[3]
          m3 = month
        when @dates[4]
          m4 = month
        when @dates[5]
          m5 = month
        when @dates[6]
          m6 = month
        when @dates[7]
          m7 = month
        when @dates[8]
          m8 = month
        when @dates[9]
          m9 = month
        when @dates[10]
          m10 = month
        when @dates[11]
          m11 = month
        when @dates[12]
          m12 = month
        when @dates[13]
          m13 = month
        when @dates[14]
          mc = month
        else
          puts "Unexpected case for all_months, month.date" 
        end 
      end

      all_months_next = Metric.where(property: p, date: @next_day_dates).order("date ASC")
      m0_n, m1_n, m2_n, m3_n, m4_n, m5_n, m6_n, m7_n, m8_n, m9_n, m10_n, m11_n, m12_n, m13_n = nil
      all_months_next.each do |month|
        case month.date
        when @next_day_dates[0]
          m0_n = month
        when @next_day_dates[1]
          m1_n = month
        when @next_day_dates[2]
          m2_n = month
        when @next_day_dates[3]
          m3_n = month
        when @next_day_dates[4]
          m4_n = month
        when @next_day_dates[5]
          m5_n = month
        when @next_day_dates[6]
          m6_n = month
        when @next_day_dates[7]
          m7_n = month
        when @next_day_dates[8]
          m8_n = month
        when @next_day_dates[9]
          m9_n = month
        when @next_day_dates[10]
          m10_n = month
        when @next_day_dates[11]
          m11_n = month
        when @next_day_dates[12]
          m12_n = month
        when @next_day_dates[13]
          m13_n = month
        else
          puts "Unexpected case for all_months_next, month.date" 
        end 
      end

      @year_leases = 0
      @year_goal = 0

      m0_data = m0.nil? ? {:percentage => -999} : m_data(leases: m0.leases_attained_adjusted, goal: m0.total_lease_goal_adjusted, percentage: m0.percent_of_lease_goal_adjusted, next_day_metric: m0_n, add_to_year: false)
      m1_data = m1.nil? ? {:percentage => -999} : m_data(leases: m1.leases_attained_adjusted, goal: m1.total_lease_goal_adjusted, percentage: m1.percent_of_lease_goal_adjusted, next_day_metric: m1_n, add_to_year: false)
      m2_data = m2.nil? ? {:percentage => -999} : m_data(leases: m2.leases_attained_adjusted, goal: m2.total_lease_goal_adjusted, percentage: m2.percent_of_lease_goal_adjusted, next_day_metric: m2_n, add_to_year: true)
      m3_data = m3.nil? ? {:percentage => -999} : m_data(leases: m3.leases_attained_adjusted, goal: m3.total_lease_goal_adjusted, percentage: m3.percent_of_lease_goal_adjusted, next_day_metric: m3_n, add_to_year: true)
      m4_data = m4.nil? ? {:percentage => -999} : m_data(leases: m4.leases_attained_adjusted, goal: m4.total_lease_goal_adjusted, percentage: m4.percent_of_lease_goal_adjusted, next_day_metric: m4_n, add_to_year: true)
      m5_data = m5.nil? ? {:percentage => -999} : m_data(leases: m5.leases_attained_adjusted, goal: m5.total_lease_goal_adjusted, percentage: m5.percent_of_lease_goal_adjusted, next_day_metric: m5_n, add_to_year: true)
      m6_data = m6.nil? ? {:percentage => -999} : m_data(leases: m6.leases_attained_adjusted, goal: m6.total_lease_goal_adjusted, percentage: m6.percent_of_lease_goal_adjusted, next_day_metric: m6_n, add_to_year: true)
      m7_data = m7.nil? ? {:percentage => -999} : m_data(leases: m7.leases_attained_adjusted, goal: m7.total_lease_goal_adjusted, percentage: m7.percent_of_lease_goal_adjusted, next_day_metric: m7_n, add_to_year: true)
      m8_data = m8.nil? ? {:percentage => -999} : m_data(leases: m8.leases_attained_adjusted, goal: m8.total_lease_goal_adjusted, percentage: m8.percent_of_lease_goal_adjusted, next_day_metric: m8_n, add_to_year: true)
      m9_data = m9.nil? ? {:percentage => -999} : m_data(leases: m9.leases_attained_adjusted, goal: m9.total_lease_goal_adjusted, percentage: m9.percent_of_lease_goal_adjusted, next_day_metric: m9_n, add_to_year: true)
      m10_data = m10.nil? ? {:percentage => -999} : m_data(leases: m10.leases_attained_adjusted, goal: m10.total_lease_goal_adjusted, percentage: m10.percent_of_lease_goal_adjusted, next_day_metric: m10_n, add_to_year: true)
      m11_data = m11.nil? ? {:percentage => -999} : m_data(leases: m11.leases_attained_adjusted, goal: m11.total_lease_goal_adjusted, percentage: m11.percent_of_lease_goal_adjusted, next_day_metric: m11_n, add_to_year: true)
      m12_data = m12.nil? ? {:percentage => -999} : m_data(leases: m12.leases_attained_adjusted, goal: m12.total_lease_goal_adjusted, percentage: m12.percent_of_lease_goal_adjusted, next_day_metric: m12_n, add_to_year: true)
      m13_data = m13.nil? ? {:percentage => -999} : m_data(leases: m13.leases_attained_adjusted, goal: m13.total_lease_goal_adjusted, percentage: m13.percent_of_lease_goal_adjusted, next_day_metric: m13_n, add_to_year: true)
      mc_data = mc.nil? ? {:percentage => -999} : m_current_data(mc.leases_attained_adjusted, mc.total_lease_goal_adjusted, mc.percent_of_lease_goal_adjusted)

      if @year_goal <= 0
        if @year_leases >= @year_goal # attained >= total_goal, then (ABS(A-T)+1)/1
          @year_leases = (@year_leases - @year_goal).abs + 1
          @year_goal = 1
          percent_of_year_goal_num = @year_leases.to_f / @year_goal.to_f * 100.0
        else # attained < total_goal, then 0/ABS(T-A)
          @year_leases = 0
          @year_goal = (@year_goal - @year_leases).abs
          percent_of_year_goal_num = @year_leases.to_f / @year_goal.to_f * 100.0    
        end
      else # total lease goal > 0
        percent_of_year_goal_num = @year_leases.to_f / @year_goal.to_f * 100.0
      end

      percent_of_year_goal_num = percent_of_year_goal_num > 100 ? 100 : percent_of_year_goal_num
      year_heart = percent_of_year_goal_num >= 100 ? '♥&#xFE0E;' : ''

      last_quarters_offset = get_last_quarters_offset()
      if last_quarters_offset == 0
        quarter_data_a = quarter_data(m_data_0: m2_data, m_data_1: m3_data, m_data_2: m4_data)
        quarter_data_b = quarter_data(m_data_0: m5_data, m_data_1: m6_data, m_data_2: m7_data)
        quarter_data_c = quarter_data(m_data_0: m8_data, m_data_1: m9_data, m_data_2: m10_data)
        quarter_data_d = quarter_data(m_data_0: m11_data, m_data_1: m12_data, m_data_2: m13_data)
      elsif last_quarters_offset == 1
        quarter_data_a = quarter_data(m_data_0: m1_data, m_data_1: m2_data, m_data_2: m3_data)
        quarter_data_b = quarter_data(m_data_0: m4_data, m_data_1: m5_data, m_data_2: m6_data)
        quarter_data_c = quarter_data(m_data_0: m7_data, m_data_1: m8_data, m_data_2: m9_data)
        quarter_data_d = quarter_data(m_data_0: m10_data, m_data_1: m11_data, m_data_2: m12_data)
      else 
        quarter_data_a = quarter_data(m_data_0: m0_data, m_data_1: m1_data, m_data_2: m2_data)
        quarter_data_b = quarter_data(m_data_0: m3_data, m_data_1: m4_data, m_data_2: m5_data)
        quarter_data_c = quarter_data(m_data_0: m6_data, m_data_1: m7_data, m_data_2: m8_data)
        quarter_data_d = quarter_data(m_data_0: m9_data, m_data_1: m10_data, m_data_2: m11_data)
      end

      {
        :id => p.id,
        :code => p.code,
        :type => p.type,
        :m0_data => m0_data,
        :m1_data => m1_data,
        :m2_data => m2_data,
        :m3_data => m3_data,
        :m4_data => m4_data,
        :m5_data => m5_data,
        :m6_data => m6_data,
        :m7_data => m7_data,
        :m8_data => m8_data,
        :m9_data => m9_data,
        :m10_data => m10_data,
        :m11_data => m11_data,
        :m12_data => m12_data,
        :m13_data => m13_data,
        :mc_data => mc_data,
        :percent_of_year_goal_num => percent_of_year_goal_num,
        :year_leases => @year_leases,
        :year_goal => @year_goal,
        :year_heart => year_heart,
        :quarter_data_a => quarter_data_a,
        :quarter_data_b => quarter_data_b,
        :quarter_data_c => quarter_data_c,
        :quarter_data_d => quarter_data_d
      }
    end    
    
    return data
  end

  def create_table_data
    table_data = @data.collect do |row| 
      col0 = row[:m0_data][:leases].nil? ? 'NA' : "#{'%0.f' % row[:m0_data][:leases]}/#{'%0.f' % row[:m0_data][:goal]}#{row[:m0_data][:heart]}"
      col1 = row[:m1_data][:leases].nil? ? 'NA' : "#{'%0.f' % row[:m1_data][:leases]}/#{'%0.f' % row[:m1_data][:goal]}#{row[:m1_data][:heart]}"
      col2 = row[:m2_data][:leases].nil? ? 'NA' : "#{'%0.f' % row[:m2_data][:leases]}/#{'%0.f' % row[:m2_data][:goal]}#{row[:m2_data][:heart]}"
      col3 = row[:m3_data][:leases].nil? ? 'NA' : "#{'%0.f' % row[:m3_data][:leases]}/#{'%0.f' % row[:m3_data][:goal]}#{row[:m3_data][:heart]}"
      col4 = row[:m4_data][:leases].nil? ? 'NA' : "#{'%0.f' % row[:m4_data][:leases]}/#{'%0.f' % row[:m4_data][:goal]}#{row[:m4_data][:heart]}"
      col5 = row[:m5_data][:leases].nil? ? 'NA' : "#{'%0.f' % row[:m5_data][:leases]}/#{'%0.f' % row[:m5_data][:goal]}#{row[:m5_data][:heart]}"
      col6 = row[:m6_data][:leases].nil? ? 'NA' : "#{'%0.f' % row[:m6_data][:leases]}/#{'%0.f' % row[:m6_data][:goal]}#{row[:m6_data][:heart]}"
      col7 = row[:m7_data][:leases].nil? ? 'NA' : "#{'%0.f' % row[:m7_data][:leases]}/#{'%0.f' % row[:m7_data][:goal]}#{row[:m7_data][:heart]}"
      col8 = row[:m8_data][:leases].nil? ? 'NA' : "#{'%0.f' % row[:m8_data][:leases]}/#{'%0.f' % row[:m8_data][:goal]}#{row[:m8_data][:heart]}"
      col9 = row[:m9_data][:leases].nil? ? 'NA' : "#{'%0.f' % row[:m9_data][:leases]}/#{'%0.f' % row[:m9_data][:goal]}#{row[:m9_data][:heart]}"
      col10 = row[:m10_data][:leases].nil? ? 'NA' : "#{'%0.f' % row[:m10_data][:leases]}/#{'%0.f' % row[:m10_data][:goal]}#{row[:m10_data][:heart]}"
      col11 = row[:m11_data][:leases].nil? ? 'NA' : "#{'%0.f' % row[:m11_data][:leases]}/#{'%0.f' % row[:m11_data][:goal]}#{row[:m11_data][:heart]}"
      col12 = row[:m12_data][:leases].nil? ? 'NA' : "#{'%0.f' % row[:m12_data][:leases]}/#{'%0.f' % row[:m12_data][:goal]}#{row[:m12_data][:heart]}"
      col13 = row[:m13_data][:leases].nil? ? 'NA' : "#{'%0.f' % row[:m13_data][:leases]}/#{'%0.f' % row[:m13_data][:goal]}#{row[:m13_data][:heart]}"
      col14 = row[:mc_data][:leases].nil? ? 'NA' : "#{'%0.f' % row[:mc_data][:leases]}/#{'%0.f' % row[:mc_data][:goal]}#{row[:mc_data][:heart]}"

      col17 = row[:quarter_data_a][:leases].nil? ? 'NA' : "#{'%0.f' % row[:quarter_data_a][:leases]}/#{'%0.f' % row[:quarter_data_a][:goal]}#{row[:quarter_data_a][:heart]}"
      col18 = row[:quarter_data_b][:leases].nil? ? 'NA' : "#{'%0.f' % row[:quarter_data_b][:leases]}/#{'%0.f' % row[:quarter_data_b][:goal]}#{row[:quarter_data_b][:heart]}"
      col19 = row[:quarter_data_c][:leases].nil? ? 'NA' : "#{'%0.f' % row[:quarter_data_c][:leases]}/#{'%0.f' % row[:quarter_data_c][:goal]}#{row[:quarter_data_c][:heart]}"
      col20 = row[:quarter_data_d][:leases].nil? ? 'NA' : "#{'%0.f' % row[:quarter_data_d][:leases]}/#{'%0.f' % row[:quarter_data_d][:goal]}#{row[:quarter_data_d][:heart]}"

      [        
        "<input class='property_id' type='hidden' value='#{row[:id]}'><span>#{row[:code]}</span>",
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
        "<span>#{col12}</span>",
        "<span>#{col13}</span>",
        "<span class='w3-text-light-grey'><i>#{col14}</i></span>",
        "<div class=\"w3-border\" style=\"width:80px;\"><div class=\"w3-white\" style=\"height:20px;width:#{'%0.f' % row[:percent_of_year_goal_num]}%\"></div></div>",
        "<span>#{'%0.f' % row[:year_leases]}/#{'%0.f' % row[:year_goal]}#{row[:year_heart]}</span>",
        "<span>#{col17}</span>",
        "<span>#{col18}</span>",
        "<span>#{col19}</span>",
        "<span>#{col20}</span>"
      ]
    end

    return table_data
  end

  def set_quarter_names
    # Q1 = 1, 2, 3
    # Q2 = 4, 5, 6
    # Q3 = 7, 8, 9
    # Q4 = 10, 11, 12
    if @end_date.month == 1 || 
      @end_date.month == 2
      last_year = (@end_date - 1.year).strftime("%y")
      @quarter_data_a_name = "Q1 '#{last_year}"
      @quarter_data_b_name = "Q2 '#{last_year}"
      @quarter_data_c_name = "Q3 '#{last_year}"
      @quarter_data_d_name = "Q4 '#{last_year}"
    end

    if @end_date.month == 3 ||
      @end_date.month == 4 || 
      @end_date.month == 5
      last_year = (@end_date - 1.year).strftime("%y")
      year = @end_date.strftime("%y")
      @quarter_data_a_name = "Q2 '#{last_year}"
      @quarter_data_b_name = "Q3 '#{last_year}"
      @quarter_data_c_name = "Q4 '#{last_year}"
      @quarter_data_d_name = "Q1 '#{year}"
    end

    if @end_date.month == 6 ||
      @end_date.month == 7 ||
      @end_date.month == 8
      last_year = (@end_date - 1.year).strftime("%y")
      year = @end_date.strftime("%y")
      @quarter_data_a_name = "Q3 '#{last_year}"
      @quarter_data_b_name = "Q4 '#{last_year}"
      @quarter_data_c_name = "Q1 '#{year}"
      @quarter_data_d_name = "Q2 '#{year}"
    end
   
    if @end_date.month == 9 ||
      @end_date.month == 10 ||
      @end_date.month == 11
      last_year = (@end_date - 1.year).strftime("%y")
      year = @end_date.strftime("%y")
      @quarter_data_a_name = "Q4 '#{last_year}"
      @quarter_data_b_name = "Q1 '#{year}"
      @quarter_data_c_name = "Q2 '#{year}"
      @quarter_data_d_name = "Q3 '#{year}"
    end

    if @end_date.month == 12
      year = @end_date.strftime("%y")
      @quarter_data_a_name = "Q1 '#{year}"
      @quarter_data_b_name = "Q2 '#{year}"
      @quarter_data_c_name = "Q3 '#{year}"
      @quarter_data_d_name = "Q4 '#{year}"
    end
  end



  def m_current_data(leases, goal, percentage)
    unless leases.nil?
      @year_leases += leases
      @year_goal += goal
      heart = percentage >= 100 ? '♥&#xFE0E;' : ''
      # return "#{'%0.f' % leases}/#{'%0.f' % goal}#{heart}"
      return {:leases => leases, :goal => goal, :heart => heart, :percentage => percentage}
    end
      
    return {:percentage => -999}
  end

  def m_data(leases:, goal:, percentage:, next_day_metric:, add_to_year:)
    unless leases.nil?
      if !next_day_metric.nil? && !next_day_metric.leases_last_24hrs.nil?
        leases += next_day_metric.leases_last_24hrs
        percentage = Metric.calc_percentage(leases, goal)
      end

      if add_to_year
        @year_leases += leases
        @year_goal += goal
      end
      heart = percentage >= 100 ? '♥&#xFE0E;' : ''
      # return "#{'%0.f' % leases}/#{'%0.f' % goal}#{heart}"
      return {:leases => leases, :goal => goal, :heart => heart, :percentage => percentage}
    end
      
    return {:percentage => -999}
  end

  def quarter_data(m_data_0:, m_data_1:, m_data_2:)
    leases = nil
    goal = nil
    if m_data_0[:leases].present?
      leases = m_data_0[:leases]
      goal = m_data_0[:goal]
    end
    if m_data_1[:leases].present?
      leases.nil? ? leases = m_data_1[:leases] : leases += m_data_1[:leases]
      goal.nil? ? goal = m_data_1[:goal] : goal += m_data_1[:goal]
    end
    if m_data_2[:leases].present?
      leases.nil? ? leases = m_data_2[:leases] : leases += m_data_2[:leases]
      goal.nil? ? goal = m_data_2[:goal] : goal += m_data_2[:goal]
    end

    unless leases.nil?
      percentage = Metric.calc_percentage(leases, goal)
      heart = percentage >= 100 ? '♥&#xFE0E;' : ''
      return {:leases => leases, :goal => goal, :heart => heart, :percentage => percentage}
    end

    return {:percentage => -999}
  end

  def get_last_quarters_offset
    # Q1 = 1, 2, 3
    # Q2 = 4, 5, 6
    # Q3 = 7, 8, 9
    # Q4 = 10, 11, 12
    if @end_date.month == 1 || 
       @end_date.month == 4 || 
       @end_date.month == 7 || 
       @end_date.month == 10
      return 1
    end

    if @end_date.month == 2 ||
       @end_date.month == 5 || 
       @end_date.month == 8 || 
       @end_date.month == 11
      return 2
    end

    if @end_date.month == 3 ||
       @end_date.month == 6 ||
       @end_date.month == 9 ||
       @end_date.month == 12
      return 0
    end

    return 0
  end

  def get_sort_column
    columns = %w[code 
      m0_data
      m1_data
      m2_data
      m3_data
      m4_data
      m5_data
      m6_data
      m7_data
      m8_data
      m9_data
      m10_data
      m11_data
      m12_data
      m13_data
      mc_data
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
    
    if sort_column == 'code'
      @data = @data.sort_by { |row| [Property.get_code_position(row[:code], row[:type]), row[:code]]  }
    elsif sort_column == 'm0_data'
      @data = @data.sort_by { |row| [Property.get_code_position(row[:code], row[:type]), row[:m0_data][:percentage]]  }
    elsif sort_column == 'm1_data'
      @data = @data.sort_by { |row| [Property.get_code_position(row[:code], row[:type]), row[:m1_data][:percentage]]  }
    elsif sort_column == 'm2_data'
      @data = @data.sort_by { |row| [Property.get_code_position(row[:code], row[:type]), row[:m2_data][:percentage]]  }
    elsif sort_column == 'm3_data'
      @data = @data.sort_by { |row| [Property.get_code_position(row[:code], row[:type]), row[:m3_data][:percentage]]  }
    elsif sort_column == 'm4_data'
      @data = @data.sort_by { |row| [Property.get_code_position(row[:code], row[:type]), row[:m4_data][:percentage]]  }
    elsif sort_column == 'm5_data'
      @data = @data.sort_by { |row| [Property.get_code_position(row[:code], row[:type]), row[:m5_data][:percentage]]  }
    elsif sort_column == 'm6_data'
      @data = @data.sort_by { |row| [Property.get_code_position(row[:code], row[:type]), row[:m6_data][:percentage]]  }
    elsif sort_column == 'm7_data'
      @data = @data.sort_by { |row| [Property.get_code_position(row[:code], row[:type]), row[:m7_data][:percentage]]  }
    elsif sort_column == 'm8_data'
      @data = @data.sort_by { |row| [Property.get_code_position(row[:code], row[:type]), row[:m8_data][:percentage]]  }
    elsif sort_column == 'm9_data'
      @data = @data.sort_by { |row| [Property.get_code_position(row[:code], row[:type]), row[:m9_data][:percentage]]  }
    elsif sort_column == 'm10_data'
      @data = @data.sort_by { |row| [Property.get_code_position(row[:code], row[:type]), row[:m10_data][:percentage]]  }
    elsif sort_column == 'm11_data'
      @data = @data.sort_by { |row| [Property.get_code_position(row[:code], row[:type]), row[:m11_data][:percentage]]  }
    elsif sort_column == 'm12_data'
      @data = @data.sort_by { |row| [Property.get_code_position(row[:code], row[:type]), row[:m12_data][:percentage]]  }
    elsif sort_column == 'm13_data'
      @data = @data.sort_by { |row| [Property.get_code_position(row[:code], row[:type]), row[:m13_data][:percentage]]  }
    elsif sort_column == 'mc_data'
      @data = @data.sort_by { |row| [Property.get_code_position(row[:code], row[:type]), row[:mc_data][:percentage]]  }
    elsif sort_column == 'percent_of_year_goal_num'
      @data = @data.sort_by { |row| [Property.get_code_position(row[:code], row[:type]), row[:percent_of_year_goal_num]]  }
    else
      @data = @data.sort_by { |row| [Property.get_code_position(row[:code], row[:type]), row[:code]]  }
    end

    if sort_direction == "desc"     
        @data = @data.reverse      
    end

    # Move Portfolio & Teams to top again
    # @data = @data.sort_by { |row| Property.get_code_position(row[:code], row[:type]) }
  end
  
  def number(value)
    number_with_precision(value, precision: 0, strip_insignificant_zeros: true)  
  end

end
