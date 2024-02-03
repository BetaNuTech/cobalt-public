class CollectionsDetailsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  include ApplicationHelper
  include ActionView::Helpers::OutputSafetyHelper
  
  # GET /collections_details/:team_code
  # GET /collections_details/:team_code.json
  def show
    @team_code = 'All'
    @team_codes = Team.where(active: true).order("code ASC").pluck('code')
    @team_codes.unshift(@team_code)

    # team_code selected
    if params[:team_code].present?
      @team_code = params[:team_code]
      if params[:team_code] != "All"
        @team_selected = Property.where(code: @team_code).first
      end
    elsif current_user.team_code
      @team_code = current_user.team_code
      @team_selected = Property.where(code: @team_code).first
    end

    if params[:date].present?
      @date = Date.strptime(params[:date], "%m/%d/%Y")
    end

    if params[:id].present?
      ref_detail = CollectionsDetail.find(params[:id])
      if ref_detail.present? && @date.present? && ref_detail.date_time.to_date != @date
        new_date_time = ref_detail.date_time - (ref_detail.date_time.to_date - @date).days
        @current_detail = CollectionsDetail.where("date_time <= ?", new_date_time).order("date_time DESC").first
      else
        @current_detail = CollectionsDetail.find(params[:id])
      end
    else
      if @date.present?
        latest_detail = CollectionsDetail.order("date_time DESC").first
        new_date_time = latest_detail.date_time - (latest_detail.date_time.to_date - @date).days
        @current_detail = CollectionsDetail.where("date_time <= ?", new_date_time).order("date_time DESC").first
      else
        @current_detail = CollectionsDetail.order("date_time DESC").first
      end
    end

    if @current_detail.present?
      @latest_date_time_for_tenants = @current_detail.date_time + 5*60
      @timestamp_string = @current_detail.date_time.iso8601

      if !params[:date].present?
        @date = @current_detail.date_time.to_date
      end
    else
      @timestamp_string = ""
      if !params[:date].present?
        @date = Date.current
      end
    end




    respond_to do |format|
      format.html do
        render_html
      end
      format.json do 
        render_datatables
      end
    end

  end
  
  private

  def render_html
    @back_arrow_html    = "<i class=\"arrow-inactive arrow-left\"></i>".html_safe
    @forward_arrow_html = "<i class=\"arrow-inactive arrow-right\"></i>".html_safe
    if @current_detail.present?
      # Determine if there ia an older record
      prev_detail = CollectionsDetail.where("date_time < ?", @current_detail.date_time).order("date_time DESC").first
      if prev_detail.present?
        if params[:team_code].present?
          @back_arrow_html = view_context.link_to("<i class=\"arrow arrow-left\"></i>".html_safe, collections_details_path(id: prev_detail.id, team_code: params[:team_code]) , class: '', data: { turbolinks: false })
        else
          @back_arrow_html = view_context.link_to("<i class=\"arrow arrow-left\"></i>".html_safe, collections_details_path(id: prev_detail.id) , class: '', data: { turbolinks: false })
        end
      end

      # Determine if there is a newwer record
      next_detail = CollectionsDetail.where("date_time > ?", @current_detail.date_time).order("date_time ASC").first
      if next_detail.present?
        if params[:team_code].present?
          @forward_arrow_html = view_context.link_to("<i class=\"arrow arrow-right\"></i>".html_safe, collections_details_path(id: next_detail.id, team_code: params[:team_code]) , class: '', data: { turbolinks: false })
        else
          @forward_arrow_html = view_context.link_to("<i class=\"arrow arrow-right\"></i>".html_safe, collections_details_path(id: next_detail.id) , class: '', data: { turbolinks: false })
        end
      end
    end

  end

  def self.define_html_colors_and_elements
    @@blue    = "#1565C0"
    @@green   = "#00695C"
    @@orange  = "#EF6C00"
    @@red     = "#C62828"
    @@light_blue   = "#2196F3"
    @@light_green  = "#009688"
    @@light_orange = "#FF9800"
    @@light_red    = "#F44336"

    @@default_color       = "black"
    @@default_light_color = "grey"

    @@up_blue = "<span style=\"color:#{@@blue};font-size:18px\">▲ <\/span>"
    @@up_green = "<span style=\"color:#{@@green};font-size:18px\">▲ <\/span>"
    @@up_orange = "<span style=\"color:#{@@orange};font-size:18px\">▲ <\/span>"
    @@up_red = "<span style=\"color:#{@@red};font-size:18px\">▲ <\/span>"
    @@up_light_blue = "<span style=\"color:#{@@light_blue};font-size:18px\">▲ <\/span>"
    @up_light_green = "<span style=\"color:#{@@light_green};font-size:18px\">▲ <\/span>"
    @@up_light_orange = "<span style=\"color:#{@@light_orange};font-size:18px\">▲ <\/span>"
    @@up_light_red = "<span style=\"color:#{@@light_red};font-size:18px\">▲ <\/span>"
    @@down_blue = "<span style=\"color:#{@@blue};font-size:18px\">▼ <\/span>"
    @@down_green = "<span style=\"color:#{@@green};font-size:18px\">▼ <\/span>"
    @@down_orange = "<span style=\"color:#{@@orange};font-size:18px\">▼ <\/span>"
    @@down_red = "<span style=\"color:#{@@red};font-size:18px\">▼ <\/span>"
    @@down_light_blue = "<span style=\"color:#{@@light_blue};font-size:18px\">▼ <\/span>"
    @@down_light_green = "<span style=\"color:#{@@light_green};font-size:18px\">▼ <\/span>"
    @@down_light_orange = "<span style=\"color:#{@@light_orange};font-size:18px\">▼ <\/span>"
    @@down_light_red = "<span style=\"color:#{@@light_red};font-size:18px\">▼ <\/span>"
  end

  def render_datatables
    @data = calculate_data
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
  
  def calculate_data
    team_property_codes = Property.properties.where(active: true, team_id: @team_selected).pluck('id')

    if @current_detail.present?
      if @team_selected.nil?
        collections_details = CollectionsDetail.where(date_time: @current_detail.date_time)
      else
        team_property_codes << @team_selected
        collections_details = CollectionsDetail.where(date_time: @current_detail.date_time, property: team_property_codes)
      end

      date_time_25hrs_ago = (@current_detail.date_time.to_time - 25.hours).to_datetime
    else
      # There's no data to process
      return
    end

    if @latest_date_time_for_tenants.present?
      latest_by_tenant_detail = CollectionsByTenantDetail.where("date_time <= ?", @latest_date_time_for_tenants).order("date_time DESC").first
    else
      latest_by_tenant_detail = CollectionsByTenantDetail.order("date_time DESC").first
    end
    if latest_by_tenant_detail.present?
      by_tenant_date_time_25hrs_ago = (latest_by_tenant_detail.date_time.to_time - 25.hours).to_datetime
      prev_by_tenant_detail = CollectionsByTenantDetail.where("date_time >= ?", by_tenant_date_time_25hrs_ago).order("date_time ASC").first
    end

    table_data = collections_details.collect do |detail|
      if detail.total_charges > 0
        percent_paid = (detail.total_paid / detail.total_charges) * 100.0
        percent_payment_plan = (detail.total_payment_plan / detail.total_charges) * 100.0
        percent_eviction_owed = (detail.total_evictions_owed / detail.total_charges) * 100.0
      else
        percent_paid = 0
        percent_payment_plan = 0
        percent_eviction_owed = 0
      end

      total_tenants = detail.num_of_unknown + detail.num_of_payment_plan + detail.num_of_paid_in_full + detail.num_of_evictions
      if total_tenants > 0
        unknown_percentage = (detail.num_of_unknown / total_tenants) * 100.0
        payment_plan_percentage = (detail.num_of_payment_plan / total_tenants) * 100.0
        pain_in_full_percentage = (detail.num_of_paid_in_full / total_tenants) * 100.0
        evictions_percentage = (detail.num_of_evictions / total_tenants) * 100.0
      else
        unknown_percentage = 0
        payment_plan_percentage = 0
        pain_in_full_percentage = 0
        evictions_percentage = 0
      end

      property_id = ""
      if detail.property.code == Property.portfolio_code()
        is_a_property = false
        order_asc = 0
        order_desc = 2
        order_string_asc = 'aaa'
        order_string_desc = 'ccc'
        property_id = detail.property.id
      elsif detail.property.type == 'Team'
        is_a_property = false
        order_asc = 1
        order_desc = 1
        order_string_asc = 'bbb'
        order_string_desc = 'bbb'
        property_id = detail.property.id
      else
        is_a_property = true
        order_asc = 2
        order_desc = 0
        order_string_asc = 'ccc'
        order_string_desc = 'aaa'
        property_id = detail.property.id
      end

      # Find oldest (within 25 hrs) to compare change to
      detail_prev = CollectionsDetail.where("date_time >= ?", date_time_25hrs_ago).where(property: detail.property).order("date_time ASC").first
      unknown_change_percentage = 0
      payment_plan_change_percentage = 0
      pain_in_full_change_percentage = 0
      evictions_change_percentage = 0
      if detail_prev.present? && detail_prev.id != detail.id
        if detail_prev.num_of_unknown > 0
          unknown_change_percentage = ((detail.num_of_unknown - detail_prev.num_of_unknown) / detail_prev.num_of_unknown) * 100.0
        elsif detail.num_of_unknown > 0
          unknown_change_percentage = 100
        end
        if detail_prev.num_of_payment_plan > 0
          payment_plan_change_percentage = ((detail.num_of_payment_plan - detail_prev.num_of_payment_plan) / detail_prev.num_of_payment_plan) * 100.0
        elsif detail.num_of_payment_plan > 0
          payment_plan_change_percentage = 100
        end
        if detail_prev.num_of_paid_in_full > 0
          pain_in_full_change_percentage = ((detail.num_of_paid_in_full - detail_prev.num_of_paid_in_full) / detail_prev.num_of_paid_in_full) * 100.0
        elsif detail.num_of_paid_in_full > 0
          pain_in_full_change_percentage = 100
        end
        if detail_prev.num_of_evictions > 0
          evictions_change_percentage = ((detail.num_of_evictions - detail_prev.num_of_evictions) / detail_prev.num_of_evictions) * 100.0
        elsif detail.num_of_evictions > 0
          evictions_change_percentage = 100
        end
      end

      # Find number of tenants that owe more than $100, and number of payment plans
      all_tenants = []
      tenants_on_payment_plan = []
      percent_tenants_on_payment_plan = 0
      percent_change_units_on_payment_plan = 0
      if latest_by_tenant_detail.present?
        if detail.property.code == Property.portfolio_code()
          all_tenants = CollectionsByTenantDetail.where(date_time: latest_by_tenant_detail.date_time)
        elsif detail.property.type == 'Team'
          team_property_codes = Property.properties.where(active: true, team_id: detail.property).pluck('id')
          all_tenants = CollectionsByTenantDetail.where(date_time: latest_by_tenant_detail.date_time, property: team_property_codes)
        else
          all_tenants = CollectionsByTenantDetail.where(date_time: latest_by_tenant_detail.date_time, property: detail.property)
        end
        tenants_on_payment_plan = all_tenants.select { |n| n.payment_plan }


        if prev_by_tenant_detail.present? && prev_by_tenant_detail.id != latest_by_tenant_detail.id
          if detail.property.code == Property.portfolio_code()
            prev_all_tenants = CollectionsByTenantDetail.where(date_time: prev_by_tenant_detail.date_time)
          elsif detail.property.type == 'Team'
            team_property_codes = Property.properties.where(active: true, team_id: detail.property).pluck('id')
            prev_all_tenants = CollectionsByTenantDetail.where(date_time: prev_by_tenant_detail.date_time, property: team_property_codes)
          else
            prev_all_tenants = CollectionsByTenantDetail.where(date_time: prev_by_tenant_detail.date_time, property: detail.property)
          end
          prev_tenants_on_payment_plan = prev_all_tenants.select { |n| n.payment_plan }    

          if detail.num_of_units > 0
            percent_change_units_on_payment_plan = ((tenants_on_payment_plan.count - prev_tenants_on_payment_plan.count) / detail.num_of_units) * 100.0
          elsif tenants_on_payment_plan.count > 0
            percent_change_units_on_payment_plan = 100
          end
        end
      end
      all_tenants_count = all_tenants.count
      tenants_on_payment_plan_count = tenants_on_payment_plan.count
      if all_tenants_count > 0
        percent_tenants_on_payment_plan = (tenants_on_payment_plan_count / all_tenants_count) * 100.0
      end

      # Check if a property has any collection tenanta with payment plan
      delinquent_payment_plans_exist = false
      delinquent_payment_plan_tenants = all_tenants.select { |n| n.payment_plan_delinquent }
      if delinquent_payment_plan_tenants.count > 0
        delinquent_payment_plans_exist = true
      end

      tenants_with_no_notes_count = 0
      if all_tenants.count > 0
        tenants_with_no_notes = all_tenants.select { |n| n.last_note.nil? || n.last_note.strip == "" }
        tenants_with_no_notes_count = tenants_with_no_notes.count
      end

      {
        :order_asc => order_asc,
        :order_desc => order_desc,
        :order_string_asc => order_string_asc,
        :order_string_desc => order_string_desc,
        :id => detail.id,
        :latest_collectiions_by_tenant_detail_id => latest_by_tenant_detail.id,
        :property_id => property_id,
        :is_a_property => is_a_property,
        :property_code => detail.property.code,
        :units => detail.num_of_units.to_i,
        :occupancy => detail.occupancy,
        :percent_paid => percent_paid,
        :percent_payment_plan => percent_payment_plan,
        :percent_eviction_owed => percent_eviction_owed,
        :num_of_unknown => detail.num_of_unknown.to_i,
        :num_of_payment_plan => detail.num_of_payment_plan.to_i,
        :num_of_paid_in_full => detail.num_of_paid_in_full.to_i,
        :num_of_evictions => detail.num_of_evictions.to_i,
        :paid_full_color_code => detail.paid_full_color_code,
        :paid_full_with_pp_color_code => detail.paid_full_with_pp_color_code,
        :unknown_percentage => unknown_percentage,
        :payment_plan_percentage => payment_plan_percentage,
        :pain_in_full_percentage => pain_in_full_percentage,
        :evictions_percentage => evictions_percentage,
        :unknown_change_percentage => unknown_change_percentage,
        :payment_plan_change_percentage => payment_plan_change_percentage,
        :pain_in_full_change_percentage => pain_in_full_change_percentage,
        :evictions_change_percentage => evictions_change_percentage,
        :all_tenants_count => all_tenants_count,
        :tenants_on_payment_plan_count => tenants_on_payment_plan_count,
        :percent_tenants_on_payment_plan => percent_tenants_on_payment_plan,
        :percent_change_units_on_payment_plan => percent_change_units_on_payment_plan,
        :delinquent_payment_plans_exist => delinquent_payment_plans_exist,
        :tenants_with_no_notes_count => tenants_with_no_notes_count,
        :avg_daily_occ_adj => detail.avg_daily_occ_adj,
        :avg_daily_trend_2mo_adj => detail.avg_daily_trend_2mo_adj,
        :past_due_rents => detail.past_due_rents,
        :covid_adjusted_rents => detail.covid_adjusted_rents
      }
    end 
    
    # Push Portfolio data
    # NOTE: Now being sent as well
    # if @team_code == 'All'
    #   table_data.push(portfolio_data(table_data))
    #   @team_codes.each do |team_code|
    #     unless team_code == 'All'
    #       table_data.push(team_data(team_code, table_data))
    #     end
    #   end
    # else
    #   table_data.push(team_data(@team_code, table_data))
    # end
    
    return table_data
  end


  def create_table_data
    total_bar_width = 400
    table_data = @data.collect do |row|

      if row[:team_id].nil?
        team_html = ''
      else
        team_html = "<input class='team_id' type='hidden' value='#{row[:team_id]}'>"
      end

      if row[:property_id] == ""
        property_id_html = ""
        collections_by_tenant_span = ""
      else
        property_id_html = "<input class='property_id' type='hidden' value='#{row[:property_id]}'>"
        collections_by_tenant_span = " collections_by_tenant_details='show'"
      end

      bar_width_one = total_bar_width * (row[:percent_paid] / 100.0)
      bar_width_two = total_bar_width * (row[:percent_payment_plan] / 100.0)
      bar_width_four = total_bar_width * (row[:percent_eviction_owed] / 100.0)
      bar_width_three = total_bar_width - (bar_width_one + bar_width_two + bar_width_four)

      color_one = CollectionsDetailsController.color_for_paid_in_full(row[:paid_full_color_code])
      color_two = CollectionsDetailsController.color_for_payment_plan(row[:paid_full_with_pp_color_code])
      color_four = 'red'

      CollectionsDetailsController.define_html_colors_and_elements()
      unknowns_arrow = ""
      paid_arrow = ""
      plan_arrow = ""
      evicts_arrow = ""

      if row[:unknown_change_percentage] > 0
        unknowns_arrow = @@up_red
      else row[:unknown_change_percentage] < 0
        if    row[:unknown_change_percentage] >= -2
          unknowns_arrow = @@down_red
        elsif row[:unknown_change_percentage] >= -5
          unknowns_arrow = @@down_orange
        elsif row[:unknown_change_percentage] >= -10
          unknowns_arrow = @@down_green
        else
          unknowns_arrow = @@down_blue
        end 
      end

      if row[:pain_in_full_change_percentage] > 0
        if    row[:pain_in_full_change_percentage] <= 2
          paid_arrow = @@up_red
        elsif row[:pain_in_full_change_percentage] <= 5
          paid_arrow = @@up_orange
        elsif row[:pain_in_full_change_percentage] <= 10
          paid_arrow = @@up_green
        else
          paid_arrow = @@up_blue
        end
      else row[:pain_in_full_change_percentage] < 0
        paid_arrow = @@down_red
      end

      if row[:all_tenants_count] > 0
        if row[:percent_change_units_on_payment_plan] < 0
          if row[:percent_change_units_on_payment_plan] >= -2
            plan_arrow = @@down_green
          else
            plan_arrow = @@down_blue
          end
        elsif row[:percent_change_units_on_payment_plan] > 0
          if    row[:percent_change_units_on_payment_plan] <= 2
            plan_arrow = @@up_orange
          else
            plan_arrow = @@up_red
          end 
        end
      end
      plan_level_color = 0
      if row[:tenants_on_payment_plan_count] > 0
        if row[:percent_tenants_on_payment_plan] > 5
          plan_level_color = 5
        else
          plan_level_color = 3
        end
      end

      if row[:evictions_change_percentage] > 0
        if    row[:evictions_change_percentage] <= 2
          evicts_arrow = @@up_light_orange
        elsif row[:evictions_change_percentage] <= 5
          evicts_arrow = @@up_orange
        elsif row[:evictions_change_percentage] <= 10
          evicts_arrow = @@up_light_red
        else
          evicts_arrow = @@up_red
        end
      else row[:evictions_change_percentage] < 0
        if    row[:evictions_change_percentage] >= -5
          evicts_arrow = @@down_light_green
        elsif row[:evictions_change_percentage] >= -10
          evicts_arrow = @@down_light_blue
        else
          evicts_arrow = @@down_blue
        end 
      end

      delinquent_payment_plans_exist_html = ''
      if row[:delinquent_payment_plans_exist] == true
        svg_link = "<svg class=\"incomplete_work_orders_svg_exclamation_mark_triangle\">#{show_svg('exclamationmark.triangle.svg')}</svg>"
        if row[:is_a_property] == true
          delinquent_payment_plans_exist_html = "<span #{collections_by_tenant_span} class='collections_compliance_issue_with_pointer'>#{svg_link}</span> "
        else
          delinquent_payment_plans_exist_html = "<span #{collections_by_tenant_span} class='collections_compliance_issue'>#{svg_link}</span> "
        end
      end

      [
        "<input class='collections_detail_id' type='hidden' value='#{row[:id]}'><input class='property_name' type='hidden' value='#{row[:property_code]}'><input class='latest_collectiions_by_tenant_detail_id' type='hidden' value='#{row[:latest_collectiions_by_tenant_detail_id]}'>#{team_html}#{property_id_html}#{delinquent_payment_plans_exist_html}<span#{collections_by_tenant_span} style=\"color:#{color_two}\"><strong>#{row[:property_code]} #{number(row[:units])}</strong></span>",
        "<span><span graph-attribute='occupancy'>#{percent(row[:occupancy])}</span> / <span graph-attribute='avg_daily_occ_adj'>#{percent(row[:avg_daily_occ_adj])}</span> / <span graph-attribute='avg_daily_trend_2mo_adj'>#{percent(row[:avg_daily_trend_2mo_adj])}</span></span>",
        "<div style=\"width:#{total_bar_width}px;\"><div class=\"w3-border\" style=\"width:#{total_bar_width}px;\"><div style=\"background-color: #{color_one}; height:20px;width:#{bar_width_one}px\"></div><div style=\"background-color: #{color_two}; height:20px;width:#{bar_width_two}px\"></div><div class=\"w3-white\" style=\"height:20px;width:#{bar_width_three}px\"></div><div style=\"background-color: #{color_four};height:20px;width:#{bar_width_four}px\"></div></div><span graph-attribute='total_paid'>#{percent(row[:percent_paid])}</span> / <span graph-attribute='total_payment_plan'>#{percent(row[:percent_payment_plan])}</span> <span class=\"evictions_owed_percentage\" graph-attribute='total_evictions_owed'>#{percent(row[:percent_eviction_owed])}</span></div>",
        "<span>#{unknowns_arrow}<span graph-attribute='num_of_unknown'>#{number(row[:num_of_unknown])}</span> (#{percent(row[:unknown_percentage])}) #{row[:tenants_with_no_notes_count]}</span>",
        "#{plan_arrow}<span class='level-#{plan_level_color}'><span graph-attribute='num_of_payment_plan'>#{number(row[:num_of_payment_plan])}</span> (#{percent(row[:payment_plan_percentage])})</span>",
        "<span>#{paid_arrow}<span graph-attribute='num_of_paid_in_full'>#{number(row[:num_of_paid_in_full])}</span> (#{percent(row[:pain_in_full_percentage])})</span>",
        "<span>#{evicts_arrow}<span graph-attribute='num_of_evictions'>#{number(row[:num_of_evictions])}</span> (#{percent(row[:evictions_percentage])})</span>",
        "<span><span graph-attribute='past_due_rents'>#{money(row[:past_due_rents])}</span> / <span graph-attribute='covid_adjusted_rents'>#{money(row[:covid_adjusted_rents])}</span></span>"  
      ]
    end    
    
    return table_data
  end
  
  def number(value)
    number_with_precision(value, precision: 0, strip_insignificant_zeros: true)  
  end

  def money(value)
    number_to_currency(value, precision: 0, strip_insignificant_zeros: false)  
  end
  
  def percent(value)
    number_to_percentage(value, precision: 1, strip_insignificant_zeros: true)
  end

  def get_sort_column
    columns = %w[property_code 
      occupancy_trending
      total_paid
      num_of_unknown
      num_of_payment_plan
      num_of_paid_in_full 
      num_of_evictions
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
    
    if sort_direction == "asc"
      if sort_column == "property_code"
        @data = @data.sort_by { |row| [row[:order_string_asc], row[:property_code]] }
      elsif sort_column == "occupancy_trending"
        @data = @data.sort_by { |row| [row[:order_asc], row[:occupancy]] }
      elsif sort_column == "total_paid"
        @data = @data.sort_by { |row| [row[:order_desc], (row[:percent_paid] + row[:percent_payment_plan])] }
        @data = @data.reverse
      elsif sort_column == "num_of_unknown"
        @data = @data.sort_by { |row| [row[:order_asc], row[:num_of_unknown]] }
      elsif sort_column == "num_of_payment_plan"
        @data = @data.sort_by { |row| [row[:order_asc], row[:num_of_payment_plan]] }
      elsif sort_column == "num_of_paid_in_full"
        @data = @data.sort_by { |row| [row[:order_asc], row[:num_of_paid_in_full]] }
      elsif sort_column == "num_of_evictions"
        @data = @data.sort_by { |row| [row[:order_asc], row[:num_of_evictions]] }
      else
        @data = @data.sort_by { |row| [row[:property_code], row[:order_string_asc]] }
      end
    else
      if sort_column == "property_code"
        @data = @data.sort_by { |row| [row[:order_string_desc], row[:property_code]] }
        @data = @data.reverse
      elsif sort_column == "occupancy_trending"
        @data = @data.sort_by { |row| [row[:order_desc], row[:occupancy]] }
        @data = @data.reverse
      elsif sort_column == "total_paid"
        @data = @data.sort_by { |row| [row[:order_desc], row[:percent_eviction_owed]] }
        @data = @data.reverse
      elsif sort_column == "num_of_unknown"
        @data = @data.sort_by { |row| [row[:order_desc], row[:num_of_unknown]] }
        @data = @data.reverse
      elsif sort_column == "num_of_payment_plan"
        @data = @data.sort_by { |row| [row[:order_desc], row[:num_of_payment_plan]] }
        @data = @data.reverse
      elsif sort_column == "num_of_paid_in_full"
        @data = @data.sort_by { |row| [row[:order_desc], row[:num_of_paid_in_full]] }
        @data = @data.reverse
      elsif sort_column == "num_of_evictions"
        @data = @data.sort_by { |row| [row[:order_desc], row[:num_of_evictions]] }
        @data = @data.reverse
      else
        @data = @data.sort_by { |row| [row[:order_string_desc], row[:property_code]] }
        @data = @data.reverse
      end
    end

  end

  def self.color_for_paid_in_full(color_code)
    CollectionsDetailsController.define_html_colors_and_elements()

    if color_code.nil?
      return "black"
    end

    code = color_code.to_i

    if code == 3
      return @@blue
    elsif code == 2
      return @@green
    elsif code == 1
      return @@orange
    elsif code == 0
      return @@red
    else
      return @@default_color
    end
      
    return @@default_color
  end

  def self.color_for_payment_plan(color_code)
    CollectionsDetailsController.define_html_colors_and_elements()

    if color_code.nil?
      return "black"
    end

    code = color_code.to_i

    if code == 3
      return @@light_blue
    elsif code == 2
      return @@light_green
    elsif code == 1
      return @@light_orange
    elsif code == 0
      return @@light_red
    else
      return @@default_light_color
    end
      
    return @@default_light_color
  end


end
