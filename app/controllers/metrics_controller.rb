class MetricsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  include ApplicationHelper
  include ActionView::Helpers::OutputSafetyHelper
  
  def index
    if params[:date].present?
      @date =  Date.strptime(params[:date], "%m/%d/%Y")
    else
      # @date = Time.now.to_date - 1.day # Previous day
      @date = Time.now.to_date
    end

    @team_id = current_user.get_team_id

    @team_codes = Team.where(active: true).order("code ASC").pluck('code')

    # team_code selected by non-team user
    if params[:team_code]
      @team_selected = Property.where(code: params[:team_code]).first
      @team_codes = @team_codes.sort_by { |code| @team_selected.code == code ? 0 : 1 }
    end

    @chart_metric_attributes = MetricChartData.valid_metric_attributes().sort
    properties = Property.where(active: true).order("code ASC")
    properties = properties.sort_by { |p| Property.get_code_position(p.code, p.type) }
    @property_codes = []
    if @team_selected && !current_user.view_all_properties
      properties.each do |p| 
        if p == @team_selected || p.team_id == @team_selected.id
          @property_codes.append(p.code)
        end
      end
    elsif @team_id && !current_user.view_all_properties
      properties.each do |p| 
        if p.id == @team_id || p.team_id == @team_id
          @property_codes.append(p.code)
        end
      end
    else
      properties.each do |p| 
        @property_codes.append(p.code)
      end
    end

    @maint_user = current_user.is_a_maint_user
    if params[:manager_view].present? && params[:manager_view] == "true"
      @manager_view = true
      @maint_user = false
    else
      @manager_view = false
    end

    @admin_user = current_user.is_an_admin_user
    @corporate_user = current_user.is_a_corporate_user

    # All active codes, in order

    @conversions_for_properties_link = view_context.link_to("View All Leads Problems", conversions_for_properties_path(), class: 'leads_problem_link', data: { turbolinks: false })
    @bluebot_rollup_report_link = view_context.link_to("Bluebot Rollup Report", bluebot_rollup_report_path(), class: 'bluebot_link', data: { turbolinks: false })
    @costar_market_data_link = view_context.link_to("Costar Market Data", costar_market_data_path(), class: 'costar_link', data: { turbolinks: false })
    @collections_details_link = view_context.link_to("Collections Drill-Down", collections_details_path(), class: 'collections_details_link', data: { turbolinks: false })
    @recruiting_link = view_context.link_to("Recruiting", workable_jobs_path(), class: 'recruiting_link', data: { turbolinks: false })

    respond_to do |format|
      format.html
      format.json do 
        render_datatables
      end
    end

  end

  def toggle_team_ui
    current_user.view_all_properties = !current_user.view_all_properties
    current_user.save!
  end
  
  private
  def render_datatables
    # If user's pref is team only view
    # 1. Grab user's team, if existing
    # 2. Pull only properties that have the team, and the team itself
    if @team_selected && !current_user.view_all_properties
      team_property_ids = Property.where(active: true, team_id: @team_selected.id).pluck('id')
      team_property_ids.append(@team_selected.id)
      @metrics = Metric.where(date: @date, property: team_property_ids)
      .order("position ASC")
      .includes(property: [:current_blue_shift])
      .joins(:property)
    elsif @team_id && !current_user.view_all_properties
      team_property_ids = Property.where(active: true, team_id: @team_id).pluck('id')
      team_property_ids.append(@team_id)
      @metrics = Metric.where(date: @date, property_id: team_property_ids)
      .order("position ASC")
      .includes(property: [:current_blue_shift])
      .joins(:property)
    else
      @metrics = Metric.where(date: @date)
      .order("position ASC")
      .includes(property: [:current_blue_shift])
      .joins(:property)
    end

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
  
  def create_table_data
    table_data = @metrics.collect do |m|
      if @maint_user
      #   if m.property.maint_blue_shift_status == "required" 
      #     if can?(:create_maint_blue_shift, m.property)
      #       property_name = view_context.link_to(m.property.code, new_property_maint_blue_shift_path(property_id: m.property_id) , class: 'flash flash_red')
      #     else
      #       property_name = "<span class='flash flash_red'>#{m.property.code}</span>"
      #     end
      #   elsif m.property.maint_blue_shift_status == "pending"
      #     user_property = UserProperty.where(user: current_user, property: m.property).first
      #     blue_shift = m.property.current_maint_blue_shift
          
      #     if m.property.current_maint_blue_shift.present? and m.property.current_maint_blue_shift.any_fix_by_date_expired? 
      #       css_class = "flash_row_red"
    
      #     # Has been viewed
      #     elsif user_property.present? and user_property.maint_blue_shift_status == "viewed"
      #       css_class = "blue"
      #     # Needs help with has not been viewed
      #     elsif blue_shift.need_help_with_no_selected_problems?
      #       css_class = "flash_row_blue"
      #     # Has not been viewed
      #     else
      #       css_class = "flash flash_blue"
      #     end
          
      #     if can?(:create_maint_blue_shift, m.property)
      #       property_name = view_context.link_to(m.property.code, property_maint_blue_shift_path(m.property_id, blue_shift), class: css_class)
      #     else
      #       property_name = "<span class='#{css_class}'>#{m.property.code}</span>"
      #     end
  
      #   else
      #     if can?(:create_maint_blue_shift, m.property)
      #       property_name = view_context.link_to(m.property.code, new_property_maint_blue_shift_path(property_id: m.property_id))
      #     else
      #       property_name = m.property.code
      #     end        
      #   end  

        property_name = m.property.code
      else
        if m.property.code == Property.portfolio_code()
          property_name = m.property.code
        elsif m.property.type == "Team"
          property_name = view_context.link_to(m.property.code, trm_blueshift_metrics_path(team_id: m.property_id), data: { turbolinks: false })
        elsif m.property.blue_shift_status == "required" 
          css_class = "flash flash_red"
          if can?(:create_blue_shift, m.property)
            property_name = view_context.link_to(m.property.code, new_property_blue_shift_path(property_id: m.property_id) , class: css_class, data: { turbolinks: false })
            svg_link = "<svg class=\"metrics_svg_blueshift_board\">#{show_svg('doc.text.below.ecg.svg')}</svg>"
            blue_shift_board_link = "<a href=\"#{blue_shift_boards_path(property_id: m.property_id)}\">#{svg_link}</a>"
          else
            property_name = "<span class='#{css_class}'>#{m.property.code}</span>"
          end
        elsif m.property.blue_shift_status == "pending"
          user_property = UserProperty.where(user: current_user, property: m.property).first
          blue_shift = m.property.current_blue_shift
          
          if m.property.current_blue_shift.present? and m.property.current_blue_shift.any_fix_by_date_expired? 
            css_class = "flash_row_red"
    
          # Has been viewed
          elsif user_property.present? and user_property.blue_shift_status == "viewed"
            css_class = "blue"
          # Needs help with has not been viewed
          elsif blue_shift.need_help_with_no_selected_problems?
            css_class = "flash_row_blue"
          # Has not been viewed
          else
            css_class = "flash flash_blue"
          end
          
          if can?(:create_blue_shift, m.property)
            property_name = view_context.link_to(m.property.code, property_blue_shift_path(m.property_id, blue_shift), class: css_class, data: { turbolinks: false })
            svg_link = "<svg class=\"metrics_svg_blueshift_board\">#{show_svg('doc.text.below.ecg.svg')}</svg>"
            blue_shift_board_link = "<a href=\"#{blue_shift_boards_path(property_id: m.property_id)}\">#{svg_link}</a>"
          else
            property_name = "<span class='#{css_class}'>#{m.property.code}</span>"
          end
  
        else
          if can?(:create_blue_shift, m.property)
            property_name = view_context.link_to(m.property.code, new_property_blue_shift_path(property_id: m.property_id), data: { turbolinks: false })
            svg_link = "<svg class=\"metrics_svg_blueshift_board\">#{show_svg('doc.text.below.ecg.svg')}</svg>"
            blue_shift_board_link = "<a href=\"#{blue_shift_boards_path(property_id: m.property_id)}\">#{svg_link}</a>"
          else
            property_name = m.property.code
          end        
        end  
      end

      # Calculate 10-day trend on trending_average_daily [ASSUMPTION: all metrics are 1 day apart]
      trendline_slope = ''
      trend_level = 0
      ten_m = Metric.where(property: m.property).where("date <= ?", @date).where.not(trending_average_daily: nil).order("date DESC").first(10)
      if ten_m.count == 10
        values = ten_m.reverse_each.map{ |e| e.trending_average_daily }
        trend_line_data = values.trend_line()
        slope = trend_line_data[:slope]
        if slope > 0
          trendline_slope = '▲ '
          if slope > 0.20
            trend_level = 1
          else
            trend_level = 2
          end
        elsif slope < 0
            trendline_slope = '▼ '
          if slope >= -0.20
            trend_level = 3
          else
            trend_level = 6
          end
        end
      end

      # Check for Compliance Issues
      compliance_html = ''
      compliance_issues = ComplianceIssue.where(date: @date, property: m.property, trm_notify_only: false)
      if compliance_issues.present?
        svg_link = "<svg class=\"metrics_svg_exclamation_mark_triangle\">#{show_svg('exclamationmark.triangle.svg')}</svg>"
        compliance_html = "<span class='metrics_compliance_issue'>#{svg_link}</span>"
      end

      # Switch to Blueshift Board Link (Not for Production, for now)
      if can?(:create_blue_shift, m.property)
        # svg_link = "<svg class=\"metrics_svg_blueshift_board\">#{show_svg('doc.text.below.ecg.svg')}</svg>"
        # blue_shift_board_link = "<a href=\"#{blue_shift_boards_path(property_id: m.property_id)}\">#{svg_link}</a>"
        property_name = view_context.link_to(m.property.code, blue_shift_boards_path(property_id: m.property_id), class: css_class, data: { turbolinks: false })
      end

      # Property Units
      if m.property.code == Property.portfolio_code()
        trending_next_month_html = "#{percent m.trending_next_month}"
      else  
        trending_next_month_html = "<a onClick=\"show_hud()\" href=\"#{property_units_path(property_id: m.property_id)}\">#{percent m.trending_next_month}</a>"
        # trending_next_month_html = view_context.link_to("#{percent m.trending_next_month}", property_units_path(property_id: m.property_id))
      end

      if @maint_user
        [
          "<input class='metric_id' type='hidden' value='#{m.id}'><input class='property_id' type='hidden' value='#{m.property_id}'><input class='date' type='hidden' value='#{@date}'><span class='property_name'>#{property_name}</span> #{number m.number_of_units } <span data-metric='physical_occupancy' class='level-#{m.physical_occupancy_level}'>(#{percent m.physical_occupancy})</span> <span data-metric='rolling_30_net_sales'>#{number m.rolling_30_net_sales}</span>:<span data-metric='rolling_10_net_sales'>#{number m.rolling_10_net_sales}</span>",
          "<span data-metric='cnoi' class='level-#{m.cnoi_level}'>#{percent(m.cnoi)}</span> (<span class='level-#{m.cnoi_projected_level}'>#{percent(m.projected_cnoi)}</span>)",
          "<span class='level-#{m.maintenance_percentage_ready_over_vacant_level}'><span data-metric='maintenance_all_graphs'>M</span> #{percent m.maintenance_percentage_ready_over_vacant}</span> \
            <span class='level-#{m.maintenance_number_not_ready_level}'>(#{number m.maintenance_number_not_ready}:#{number m.maintenance_turns_completed})</span>",
          "<span class='level-#{m.maintenance_open_wos_level}' data-incomplete-work-orders='show'>#{number(m.maintenance_open_wos)}</span><span> / #{number(m.maintenance_total_open_work_orders)}</span>",
#          "<span class='level-#{m.expenses_percentage_of_past_month_level}'><span data-metric='expenses_all_graphs'>E</span> (#{percent m.expenses_percentage_of_past_month})</span> <span class='level-#{m.expenses_percentage_of_budget_level}'>#{percent m.expenses_percentage_of_budget}</span>",
          "<span><span data-metric='renewals_all_graphs'>R</span> (<span class='level-#{m.renewals_unknowns_level}'>#{number m.renewals_unknown}</span>) #{number m.renewals_number_renewed} / <span class='level-#{m.renewals_percentage_renewed_level}'>#{percent m.renewals_percentage_renewed}</span> / <span>#{number m.renewals_residents_month_to_month}</span></span>",
          "<span class='level-#{m.occupancy_average_daily_level}'><span data-metric='occupancy_all_graphs'>O</span> #{percent m.occupancy_average_daily} / #{percent m.occupancy_budgeted_economic}</span>",
          "<span class='level-#{trend_level}'><span data-metric='trending_all_graphs'>T</span> #{trendline_slope}</span><span class='level-#{m.trending_next_month_level}'>#{trending_next_month_html}</span> / <span class='level-#{m.trending_average_daily_level}'>#{percent m.trending_average_daily}</span>"
          # "<span class='level-0'><span data-metric='average_rents_all_graphs'>A</span> <span data-rent-change-reasons='show'>#{number m.average_market_rent}</span> / <span class='level-#{m.average_rents_net_effective_level}'>#{number m.average_rents_net_effective} / #{number m.average_rents_net_effective_budgeted}</span> / <span class='level-#{m.average_rent_delta_percent_level}'>#{percent m.average_rent_delta_percent}</span></span>",
          # "<span class='level-#{m.basis_level}'><span data-metric='basis_all_graphs'>B</span> #{percent m.basis}</span> <span class='level-#{m.basis_year_to_date_level}'>(#{percent m.basis_year_to_date})</span>",
          # "<span data-metric='collections_all_graphs'>C</span> <span class='level-#{m.collections_current_status_residents_with_last_month_balance_level}'>(#{number m.collections_current_status_residents_with_last_month_balance})</span> \
          #   <span class='level-#{m.collections_unwritten_off_balances_level}'>#{number m.collections_unwritten_off_balances}</span> / \
          #   <span class='level-#{m.collections_percentage_recurring_charges_collected_level}'>#{percent m.collections_percentage_recurring_charges_collected}</span> \
          #   <span class='level-#{m.collections_current_status_residents_with_current_month_balance_level}'>(#{number m.collections_current_status_residents_with_current_month_balance})</span>",
          # "<span data-metric='collections_number_of_eviction_residents' class='level-#{m.collections_number_of_eviction_residents_level}'>#{number(m.collections_number_of_eviction_residents)}</span>",
        ]
      else
        [
          "<input class='metric_id' type='hidden' value='#{m.id}'><input class='property_id' type='hidden' value='#{m.property_id}'><input class='date' type='hidden' value='#{@date}'>#{compliance_html}<span class='property_name'>#{property_name}</span> #{number m.number_of_units } <span data-metric='physical_occupancy' class='level-#{m.physical_occupancy_level}'>(#{percent m.physical_occupancy})</span> <span data-metric='rolling_30_net_sales'>#{number m.rolling_30_net_sales}</span>:<span data-metric='rolling_10_net_sales'>#{number m.rolling_10_net_sales}</span>",
          "<span class='level-#{m.basis_level}'><span data-metric='basis_all_graphs'>B</span> #{percent m.basis}</span> <span class='level-#{m.basis_year_to_date_level}'>(#{percent m.basis_year_to_date})</span>",
          "<span data-metric='cnoi' class='level-#{m.cnoi_level}'>#{percent(m.cnoi)}</span> (<span class='level-#{m.cnoi_projected_level}'>#{percent(m.projected_cnoi)}</span>)",
          "<span class='level-#{trend_level}'><span data-metric='trending_all_graphs'>T</span> #{trendline_slope}</span><span class='level-#{m.trending_next_month_level}'>#{trending_next_month_html}</span> / <span class='level-#{m.trending_average_daily_level}'>#{percent m.trending_average_daily}</span>", 
          "<span class='level-#{m.occupancy_average_daily_level}'><span data-metric='occupancy_all_graphs'>O</span> #{percent m.occupancy_average_daily} / #{percent m.occupancy_budgeted_economic}</span>",
          "<span class='level-0'><span data-metric='average_rents_all_graphs'>A</span> <span data-rent-change-reasons='show' class='level-#{m.average_market_rent_level}'>#{number m.average_market_rent}</span> (#{number m.average_rent_weighted_per_unit_specials}) / <span class='level-#{m.average_rents_net_effective_level}'>#{number m.average_rents_net_effective} / #{number m.average_rents_net_effective_budgeted}</span> / <span class='level-#{m.average_rent_delta_percent_level}'>#{percent m.average_rent_delta_percent}</span> (<span style='color:#FF33F6'>#{percent m.average_rent_year_over_year_without_vacancy}</span> <span style='color:#9033FF'>#{percent m.average_rent_year_over_year_with_vacancy}</span>)</span>",
          "<span class='level-#{m.concessions_level}'>N #{number m.concessions_per_unit} / #{number m.concessions_budgeted_per_unit}</span>",
#          "<span class='level-#{m.expenses_percentage_of_past_month_level}'><span data-metric='expenses_all_graphs'>E</span> (#{percent m.expenses_percentage_of_past_month})</span> <span class='level-#{m.expenses_percentage_of_budget_level}'>#{percent m.expenses_percentage_of_budget}</span>",
          "<span><span data-metric='renewals_all_graphs'>R</span> (<span data-renewals-unknown='show' class='level-#{m.renewals_unknowns_level}'>#{number m.renewals_unknown}</span>) #{number m.renewals_number_renewed} / <span class='level-#{m.renewals_percentage_renewed_level}'>#{percent m.renewals_percentage_renewed}</span> / <span>#{number m.renewals_residents_month_to_month}</span> / <span>#{percent m.renewals_ytd_percentage}</span></span>",
          "<span data-metric='collections_all_graphs'>C</span> <span data-collections-non-eviction-past20='show' class='level-#{m.collections_current_status_residents_with_last_month_balance_level}'>(#{number m.collections_current_status_residents_with_last_month_balance})</span> \
            <span class='level-#{m.collections_unwritten_off_balances_level}'>#{number m.collections_unwritten_off_balances}</span> / \
            <span class='level-#{m.collections_percentage_recurring_charges_collected_level}'>#{percent m.collections_percentage_recurring_charges_collected}</span> \
            <span class='level-#{m.collections_current_status_residents_with_current_month_balance_level}'>(#{number m.collections_current_status_residents_with_current_month_balance})</span>",
          "<span data-metric='collections_number_of_eviction_residents' class='level-#{m.collections_number_of_eviction_residents_level}'>#{number(m.collections_number_of_eviction_residents)}</span> (<span data-metric='collections_eviction_residents_over_two_months_due' class='level-#{m.collections_eviction_residents_over_two_months_due_level}'>#{number(m.collections_eviction_residents_over_two_months_due)}</span>)",
          "<span class='level-#{m.maintenance_percentage_ready_over_vacant_level}'><span data-metric='maintenance_all_graphs'>M</span> #{percent m.maintenance_percentage_ready_over_vacant}</span> \
            <span class='level-#{m.maintenance_number_not_ready_level}'>(#{number m.maintenance_number_not_ready}:#{number m.maintenance_turns_completed})</span>",
          "<span class='level-#{m.maintenance_open_wos_level}' data-incomplete-work-orders='show'>#{number(m.maintenance_open_wos)}</span><span> / #{number(m.maintenance_total_open_work_orders)}</span>"
        ]

        # For a One-off CSV Export of all dates, for a property
        # Open Rails Console
        # metrics = Metric.where(property_id: <ID>).order("date DESC")
        # f = File.new('property.csv', 'w')
        # metrics.each do |m| f << 
        # "#{m.date},#{m.number_of_units},#{m.physical_occupancy},#{m.rolling_30_net_sales},#{m.rolling_10_net_sales},
        # B,#{m.basis},#{m.basis_year_to_date},#{m.cnoi},#{m.projected_cnoi},
        # T,#{m.trending_next_month},#{m.trending_average_daily},
        # O,#{m.occupancy_average_daily},#{m.occupancy_budgeted_economic},
        # A,#{m.average_market_rent},#{m.average_rent_weighted_per_unit_specials},#{m.average_rents_net_effective},#{m.average_rents_net_effective_budgeted},#{m.average_rent_delta_percent},#{m.average_rent_year_over_year_without_vacancy},#{m.average_rent_year_over_year_with_vacancy},
        # N,#{m.concessions_per_unit},#{m.concessions_budgeted_per_unit},
        # R,#{m.renewals_unknown},#{m.renewals_number_renewed},#{m.renewals_percentage_renewed},#{m.renewals_residents_month_to_month},#{m.renewals_ytd_percentage},
        # C,#{m.collections_current_status_residents_with_last_month_balance},#{m.collections_unwritten_off_balances},#{ m.collections_percentage_recurring_charges_collected},#{m.collections_current_status_residents_with_current_month_balance},#{m.collections_number_of_eviction_residents},#{m.collections_eviction_residents_over_two_months_due},
        # M,#{m.maintenance_percentage_ready_over_vacant},#{m.maintenance_number_not_ready},#{m.maintenance_turns_completed},
        # #{m.maintenance_open_wos},#{m.maintenance_total_open_work_orders}\n" end        
        # f.close
      end
    end    
    
    return table_data
  end
  
  def number(value)
    number_with_precision(value, precision: 1, strip_insignificant_zeros: true)  
  end
  
  def percent(value)
    number_to_percentage(value, precision: 1, strip_insignificant_zeros: true)
  end
  
  def get_sort_column
    columns = %w[properties.code 
      basis
      cnoi
      trending_average_daily
      occupancy_average_daily 
      average_rents_net_effective
      concessions
      renewals_percentage_renewed 
      collections_current_status_residents_with_last_month_balance
      collections_number_of_eviction_residents
      maintenance_percentage_ready_over_vacant
      work_orders]

    #      expenses_percentage_of_budget 
      
    column = columns[params["order"]["0"]["column"].to_i]

    if column == "average_rents_net_effective"
      return "((average_rents_net_effective - average_rents_net_effective_budgeted)/average_rents_net_effective_budgeted)"
    end
    
    return column
  end

  def get_maint_sort_column
    columns = %w[properties.code 
      cnoi
      maintenance_percentage_ready_over_vacant
      work_orders
      renewals_percentage_renewed 
      occupancy_average_daily 
      trending_average_daily]

    # expenses_percentage_of_budget 
      
    column = columns[params["order"]["0"]["column"].to_i]
    
    return column
  end

  def sort_direction
    return params["order"]["0"]["dir"] 
  end  
  
  def set_ordering
    if @maint_user
      sort_column = get_maint_sort_column
    else
      sort_column = get_sort_column
    end

    puts "sort_column == #{sort_column}"
    puts "sort_direction == #{sort_direction}"
    
    if sort_column == "properties.code" and params['property_sort_cycle'] == "1"
      @metrics = @metrics.order("CASE WHEN properties.blue_shift_status='pending' THEN 1 WHEN properties.blue_shift_status='required' THEN 2 WHEN properties.blue_shift_status='not_required' THEN 3 END")  
    elsif sort_column == "properties.code" and params['property_sort_cycle'] == "2"
      @metrics = @metrics.order("rolling_30_net_sales ASC")  
    elsif sort_column == "properties.code" and params['property_sort_cycle'] == "3"
      @metrics = @metrics.order("rolling_10_net_sales ASC")  
    elsif sort_column == "trending_average_daily" and sort_direction == "desc"
      @metrics = @metrics.order("trending_next_month ASC")  
    elsif sort_column == "maintenance_percentage_ready_over_vacant" and sort_direction == "desc"
      @metrics = @metrics.order("maintenance_open_wos DESC")  
    elsif sort_column == "collections_current_status_residents_with_last_month_balance" and params['collection_sort_cycle'] == "2"
      @metrics = @metrics.order("collections_percentage_recurring_charges_collected ASC")  
    elsif sort_column == "collections_current_status_residents_with_last_month_balance" and params['collection_sort_cycle'] == "3"
      @metrics = @metrics.order("collections_percentage_recurring_charges_collected DESC")
    elsif sort_column == "concessions" and sort_direction == "desc"
      @metrics = @metrics.order("concessions_per_unit DESC")
    elsif sort_column == "concessions" and sort_direction == "asc"
      @metrics = @metrics.order("concessions_per_unit ASC")
    elsif sort_column == "basis" and params['basis_sort_cycle'] == "2"
      @metrics = @metrics.order("basis_year_to_date ASC")  
    elsif sort_column == "basis" and params['basis_sort_cycle'] == "3"
      @metrics = @metrics.order("basis_year_to_date DESC")  
    elsif sort_column == "work_orders" and sort_direction == "desc"
      @metrics = @metrics.order("maintenance_open_wos DESC")  
    elsif sort_column == "work_orders" and sort_direction == "asc"
      @metrics = @metrics.order("maintenance_open_wos ASC")  
    else
      @metrics = @metrics.order("#{sort_column} #{sort_direction}")  
    end    
  end
  
end
