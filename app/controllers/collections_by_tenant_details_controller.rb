class CollectionsByTenantDetailsController < ApplicationController
  include ActionView::Helpers::NumberHelper

  skip_before_action :authenticate_user!, only: :json_api
  
  # GET /collections_by_tenant_details/:team_code
  # GET /collections_by_tenant_details/:team_code.json
  def show
    # team_code selected
    if params[:property_id].present?
      @property_id = params[:property_id]
      @property = Property.find(@property_id)
      if @property.present?
        property_name = @property.full_name
      end

      latest = CollectionsDetail.order("date_time DESC").first
      if latest.present?
        detail = CollectionsDetail.where(property: @property, date_time: latest.date_time).first

        if detail.total_charges > 0
          percent_paid = (detail.total_paid / detail.total_charges) * 100.0
          percent_payment_plan = (detail.total_payment_plan / detail.total_charges) * 100.0
        else
          percent_paid = 0
          percent_payment_plan = 0
        end

        color_one = CollectionsDetailsController.color_for_paid_in_full(detail.paid_full_color_code)
        color_two = CollectionsDetailsController.color_for_payment_plan(detail.paid_full_with_pp_color_code)  

        num_of_unknown = detail.num_of_unknown.to_i
        num_of_payment_plan = detail.num_of_payment_plan.to_i
        num_of_paid_in_full = detail.num_of_paid_in_full.to_i
        num_of_evictions = detail.num_of_evictions.to_i

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

        @property_name_html = "<span style=\"color:#{color_two}\">#{property_name}</span>".html_safe
        @property_details_one_html = "<strong>Money Collected: <span style=\"color:#{color_one}\">#{percent(percent_paid)}</span></strong>, <strong>Money Payment Plan: <span style=\"color:#{color_two}\">#{percent(percent_payment_plan)}</span></strong>".html_safe
        @property_details_two_html = "<strong>Unknowns:</strong> #{num_of_unknown} (#{percent(unknown_percentage)}), <strong>Paid In Full:</strong> #{num_of_paid_in_full} (#{percent(pain_in_full_percentage)}), <strong>Payment Plan:</strong> #{num_of_payment_plan} (#{percent(payment_plan_percentage)}), <strong>Evictions:</strong> #{num_of_evictions} (#{percent(evictions_percentage)})".html_safe
      end
    end
    
    if params[:latest_collectiions_by_tenant_detail_id].present?
      @latest_detail = CollectionsByTenantDetail.find(params[:latest_collectiions_by_tenant_detail_id])
    else
      @latest_detail = CollectionsByTenantDetail.order("date_time DESC").first
    end
    if @latest_detail.present?
      @timestamp_string = @latest_detail.date_time.iso8601
    end

    respond_to do |format|
      format.html
      format.json do 
        render_datatables
      end
    end

  end

  def json_api
    token = params[:token]
    property_code = params[:property_code]

    if ENV.fetch("API_TOKEN", false) == token && property_code.present?
      property = Property.where(code: property_code)
      if property.present?
        latest_detail = CollectionsByTenantDetail.order("date_time DESC").first
        if latest_detail.present?
          collections_by_tenant_details = CollectionsByTenantDetail.where(property: property, date_time: latest_detail.date_time)
          render json: {
            timestamp: latest_detail.date_time.to_i,
            data: JSON.parse(
                collections_by_tenant_details.to_json(:only => [ 
                  :tenant_code,
                  :total_charges,
                  :total_owed,
                  :payment_plan,
                  :eviction,
                  :payment_plan_delinquent,
                  :last_note,
                  :last_note_updated_at
                ])
              )
            }
        else
          render json: {data: [] }
        end
      else
        # render json: {errors: {base: [ 'Invalid Property Code' ]}}, status: :forbidden
        render json: {error: 'Invalid Property Code'}, status: :forbidden
      end
    else
      # render json: {errors: {base: [ 'Access Denied' ]}}, status: :forbidden
      render json: {error: 'Access Denied'}, status: :forbidden
    end
  end
  
  private

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
    @show_property_code = false
    if @property.code == Property.portfolio_code()
      @show_property_code = true
      @collections_by_tenant_details = CollectionsByTenantDetail.where(date_time: @latest_detail.date_time, payment_plan_delinquent: true)
    elsif @property.type == 'Team'
      @show_property_code = true
      team_property_ids = Property.where(active: true, team_id: @property_id).pluck('id')
      @collections_by_tenant_details = CollectionsByTenantDetail.where(property: team_property_ids, date_time: @latest_detail.date_time, payment_plan_delinquent: true)
    else
      @collections_by_tenant_details = CollectionsByTenantDetail.where(property: @property, date_time: @latest_detail.date_time)
    end
    
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
    table_data = @collections_by_tenant_details.collect do |detail|

      if detail.email.present?
        email = detail.email
      else
        email = ""
      end

      mobile_phone = ""
      mobile_phone_digits = ""
      if detail.mobile_phone.present?
        digits = detail.mobile_phone.delete("^0-9")
        if digits.length >= 7
          mobile_phone = detail.mobile_phone
          mobile_phone_digits = digits
        end
      end
      home_phone = ""
      home_phone_digits = ""
      if detail.home_phone.present?
        digits = detail.home_phone.delete("^0-9")
        if digits.length >= 7 && mobile_phone_digits != digits
          home_phone = detail.home_phone
          home_phone_digits = digits
        end
      end
      office_phone = ""
      office_phone_digits = ""
      if detail.office_phone.present? 
        digits = detail.office_phone.delete("^0-9")
        if digits.length >= 7 && mobile_phone_digits != digits && home_phone_digits != digits
          office_phone = detail.office_phone
          office_phone_digits = digits
        end
      end 

      if detail.total_charges > 0
        unpaid_percentage = (detail.total_owed / detail.total_charges) * 100.0
      else
        unpaid_percentage = 0
      end

      payment_plan_sort_2 = 'Z'
      if detail.payment_plan == true
        payment_plan_sort_2 = 'A'
      end
      payment_plan_sort_3 = 'A'
      if detail.payment_plan == true
        payment_plan_sort_3 = 'Z'
      end

      # Find change from up to 25 hrs ago
      percent_change_unpaid = 0
      date_time_25hrs_ago = (detail.date_time.to_time - 25.hours).to_datetime
      prev_detail = CollectionsByTenantDetail.where("date_time >= ?", date_time_25hrs_ago).where(tenant_code: detail.tenant_code).order("date_time ASC").first
      if prev_detail.present? && prev_detail.id != detail.id
        if prev_detail.total_owed > 0
          percent_change_unpaid = ((detail.total_owed - prev_detail.total_owed) / prev_detail.total_owed) * 100.0
        elsif detail.total_owed > 0
          percent_change_unpaid = 100.0
        end
      end

      payment_plan_delinquent = false
      if detail.payment_plan_delinquent.present? && detail.payment_plan_delinquent == true
        payment_plan_delinquent = true
      end

      # Find age of notes
      if detail.payment_plan == false && detail.last_note_updated_at.present?
        date_time_current = DateTime.current
        notes_age_secs = date_time_current.to_i - detail.last_note_updated_at.to_i
      end 

      resident_name = detail.tenant_name
      if @show_property_code
        resident_name   = detail.property.code + ' / ' + detail.tenant_name
      end

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

      if @property.code == Property.portfolio_code() || @property.type == 'Team'
        if detail.payment_plan
          order_asc = 0
          order_desc = 1
          order_asc_string = 'aaa'
          order_desc_string = 'bbb'
        else
          order_asc = 1
          order_desc = 0
          order_asc_string = 'bbb'
          order_desc_string = 'aaa'
        end
      else
        order_asc = 0
        order_desc = 0
        order_asc_string = ''
        order_desc_string = ''
      end

      notes = detail.last_note
      if notes == nil
        notes = ""
      end

      status_eviction = false
      if resident_name.downcase.include? '(e)'
        status_eviction = true
      end

      status_notice = false
      if resident_name.downcase.include? '(n)'
        status_notice = true
      end

      {
        :id => detail.id,
        :property_code => detail.property.code,
        :resident_name => resident_name,
        :mobile_phone => mobile_phone,
        :mobile_phone_digits => mobile_phone_digits,
        :home_phone => home_phone,
        :home_phone_digits => home_phone_digits,
        :office_phone => office_phone,
        :office_phone_digits => office_phone_digits,
        :email => email,
        :tcode => detail.tenant_code,
        :unit => detail.unit_code,
        :rent => detail.total_charges,
        :unpaid => detail.total_owed,
        :unpaid_percentage => unpaid_percentage,
        :percent_change_unpaid => percent_change_unpaid,
        :payment_plan => detail.payment_plan,
        :notes => notes,
        :payment_plan_sort_2 => payment_plan_sort_2,
        :payment_plan_sort_3 => payment_plan_sort_3,
        :payment_plan_delinquent => payment_plan_delinquent,
        :notes_age_secs => notes_age_secs,
        :order_asc => order_asc,
        :order_desc => order_desc,
        :order_asc_string => order_asc_string,
        :order_desc_string => order_desc_string,
        :status_eviction => status_eviction,
        :status_notice => status_notice
      }
    end 
    
    return table_data
  end

  def create_table_data
    CollectionsByTenantDetailsController.define_html_colors_and_elements()

    table_data = @data.collect do |row|

      # Check for payment plan 
      if row[:payment_plan]
        payment_plan_html = "<span>YES</span>"
      else
        payment_plan_html = "<span>NO</span>"
        if row[:notes] == "" || row[:notes].nil?
          payment_plan_html = "<span class=\"level-5\">NO</span>"
        elsif row[:notes_age_secs].present? && row[:notes_age_secs] > 5.days
          payment_plan_html = "<span class=\"level-3\">NO</span>"
        end 
      end

      if @show_property_code
        resident_name_html = "<span>#{row[:resident_name]}</span>"
      else
        # resident delinquent on Payment Plan?
        if row[:payment_plan] == true && row[:payment_plan_delinquent] == true
          resident_name_html = "<span class='flash flash_red flash_background'>#{row[:resident_name]}</span>"
        else
          resident_name_html = "<span>#{row[:resident_name]}</span>"
        end
      end


      # Waiting for OPT-IN or OPT-OUT procedures
      enable_sms = false

      phones_email = ""
      if row[:mobile_phone] != ""
        if enable_sms
          sms_html = " <a href=\"sms:#{row[:mobile_phone_digits]}\"> <i class=\"fa fa-comment\" style=\"font-size:18px;color:#{@@light_blue}\"></i></a>"
        else
          sms_html = ""
        end
        phones_email += "<a href=\"tel:#{row[:mobile_phone_digits]}\"> <i class=\"fa fa-phone\" style=\"font-size:18px;color:#{@@light_blue}\"></i></a>#{sms_html} M: #{row[:mobile_phone]}"
      end
      if row[:home_phone] != ""
        if phones_email != ""
          phones_email += "<br>"
        end
        if enable_sms
          sms_html = " <a href=\"sms:#{row[:home_phone_digits]}\"> <i class=\"fa fa-comment\" style=\"font-size:18px;color:#{@@light_blue}\"></i></a>"
        else
          sms_html = ""
        end
        phones_email += "<a href=\"tel:#{row[:home_phone_digits]}\"> <i class=\"fa fa-phone\" style=\"font-size:18px;color:#{@@light_blue}\"></i></a>#{sms_html} H: #{row[:home_phone]}"
      end
      if row[:office_phone] != ""
        if phones_email != ""
          phones_email += "<br>"
        end
        if enable_sms
          sms_html = " <a href=\"sms:#{row[:office_phone_digits]}\"> <i class=\"fa fa-comment\" style=\"font-size:18px;color:#{@@light_blue}\"></i></a>"
        else
          sms_html = ""
        end
        phones_email += "<a href=\"tel:#{row[:office_phone_digits]}\"> <i class=\"fa fa-phone\" style=\"font-size:18px;color:#{@@light_blue}\"></i></a>#{sms_html} O: #{row[:office_phone]}"
      end
      if row[:email] != ""
        if phones_email != ""
          phones_email += "<br>"
        end
        phones_email += "<a style=\"font-style:bold\" href=\"mailto:#{row[:email]}\"><i class=\"fa fa-at\" style=\"font-size:18px;color:#{@@light_blue}\"></i> #{row[:email]}</a>"
      end

      unpaid_arrow = ""
      if row[:percent_change_unpaid] > 0
        unpaid_arrow = @@up_red
      elsif row[:percent_change_unpaid] < 0
        if    row[:percent_change_unpaid] >= -2
          unpaid_arrow = @@down_red
        elsif row[:percent_change_unpaid] >= -5
          unpaid_arrow = @@down_orange
        elsif row[:percent_change_unpaid] >= -10
          unpaid_arrow = @@down_green
        else
          unpaid_arrow = @@down_blue
        end
      end
      unpaid_html = "<span>#{money(row[:unpaid])} (#{percent(row[:unpaid_percentage])})</span>"
      if    row[:unpaid_percentage] <= 25
        unpaid_html = "<span style=\"color:#{@@blue}\">#{money(row[:unpaid])} (#{percent(row[:unpaid_percentage])})</span>"
      elsif row[:unpaid_percentage] <= 50
        unpaid_html = "<span style=\"color:#{@@green}\">#{money(row[:unpaid])} (#{percent(row[:unpaid_percentage])})</span>"
      elsif row[:unpaid_percentage] <= 75
        unpaid_html = "<span style=\"color:#{@@orange}\">#{money(row[:unpaid])} (#{percent(row[:unpaid_percentage])})</span>"
      elsif row[:unpaid_percentage] <= 95
        unpaid_html = "<span style=\"color:#{@@red}\">#{money(row[:unpaid])} (#{percent(row[:unpaid_percentage])})</span>"
      else
        unpaid_html = "<span class='level-5'>#{money(row[:unpaid])} (#{percent(row[:unpaid_percentage])})</span>"
      end

      darker_row_html = ''
      if !row[:payment_plan] && row[:payment_plan_delinquent]
        darker_row_html = "<input class='darker_row' type='hidden' value='1'>"
      end

      status_eviction_html = ''
      if row[:status_eviction]
        status_eviction_html = '<div style="text-align: center;">Y</div>'
      end

      status_notice_html = ''
      if row[:status_notice]
        status_notice_html = '<div style="text-align: center;">Y</div>'
      end

      [
        "<input class='collectins_by_tenant_details_id' type='hidden' value='#{row[:id]}'>#{darker_row_html}#{resident_name_html}",
        "<span>#{phones_email}</span>",
        "<span>#{row[:tcode]}</span>",
        "<span>#{row[:unit]}</span>",
        "<span>#{money(row[:rent])}</span>",
        "#{unpaid_arrow}#{unpaid_html}",
        "#{payment_plan_html}",
        "#{status_notice_html}",
        "#{status_eviction_html}",
        "<span>#{row[:notes]}</span>"
      ]
    end    
    
    return table_data
  end
  
  def number(value)
    number_with_precision(value, precision: 0, strip_insignificant_zeros: true)  
  end

  def money(value)
    number_to_currency(value, precision: 2, strip_insignificant_zeros: false)  
  end
  
  def percent(value)
    number_to_percentage(value, precision: 1, strip_insignificant_zeros: true)
  end

  def get_sort_column
    columns = %w[resident_name 
      email
      tcode
      unit
      rent
      unpaid 
      payment_plan
      notice
      eviction
      notes
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
    
    if sort_column == 'resident_name' and params['resident_sort_cycle'] == "0"
      @data = @data.sort_by { |row| [row[:order_asc_string], row[:resident_name].downcase] }
    elsif sort_column == 'resident_name' and params['resident_sort_cycle'] == "1"
      @data = @data.sort_by { |row| [row[:order_desc_string], row[:resident_name].downcase] }
      @data = @data.reverse
    elsif sort_column == 'resident_name' and params['resident_sort_cycle'] == "2"
      @data = @data.sort_by { |row| [row[:order_asc_string], row[:payment_plan_sort_2], row[:resident_name].downcase] }
    elsif sort_column == 'resident_name' and params['resident_sort_cycle'] == "3"
      @data = @data.sort_by { |row| [row[:order_asc_string], row[:payment_plan_sort_3], row[:resident_name].downcase] }
    elsif sort_direction == "asc"
      if sort_column == "email"
        @data = @data.sort_by { |row| [row[:order_asc_string], row[:email].downcase] }
      elsif sort_column == "tcode"
        @data = @data.sort_by { |row| [row[:order_asc_string], row[:tcode]] }
      elsif sort_column == "unit"
        @data = @data.sort_by { |row| [row[:order_asc_string], row[:unit]] }
      elsif sort_column == "rent"
        @data = @data.sort_by { |row| [row[:order_asc], row[:rent]] }
      elsif sort_column == "unpaid"
        @data = @data.sort_by { |row| [row[:order_asc], row[:unpaid]] }
      elsif sort_column == "payment_plan"
        @data = @data.sort_by { |row| [row[:order_asc_string], row[:payment_plan_sort_2]] }
      elsif sort_column == "notice"
        @data = @data.sort_by { |row| [row[:order_asc], row[:status_notice] ? 0 : 1] }
      elsif sort_column == "eviction"
        @data = @data.sort_by { |row| [row[:order_asc], row[:status_eviction] ? 0 : 1] }
      elsif sort_column == "notes"
        @data = @data.sort_by { |row| [row[:order_desc_string], row[:notes]] }
        @data = @data.reverse
      else
        @data = @data.sort_by { |row| [row[:order_asc_string], row[:resident_name].downcase] }
      end
    else
      if sort_column == "email"
        @data = @data.sort_by { |row| [row[:order_desc_string], row[:email].downcase] }
      elsif sort_column == "tcode"
        @data = @data.sort_by { |row| [row[:order_desc_string], row[:tcode]] }
      elsif sort_column == "unit"
        @data = @data.sort_by { |row| [row[:order_desc_string], row[:unit]] }
      elsif sort_column == "rent"
        @data = @data.sort_by { |row| [row[:order_desc], row[:rent]] }
      elsif sort_column == "unpaid"
        @data = @data.sort_by { |row| [row[:order_desc], row[:unpaid]] }
      elsif sort_column == "payment_plan"
        @data = @data.sort_by { |row| [row[:order_desc_string], row[:payment_plan_sort_2]] }
      elsif sort_column == "notice"
        @data = @data.sort_by { |row| [row[:order_desc], row[:status_notice] ? 0 : 1] }
      elsif sort_column == "eviction"
        @data = @data.sort_by { |row| [row[:order_desc], row[:status_eviction] ? 0 : 1] }
      elsif sort_column == "notes"
        @data = @data.sort_by { |row| [row[:order_asc_string], row[:notes]] }
        @data = @data.reverse
      else
        @data = @data.sort_by { |row| [row[:order_desc_string], row[:resident_name].downcase] }
      end

      @data = @data.reverse
    end

  end


end
