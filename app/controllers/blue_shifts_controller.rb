require 'httparty'

class BlueShiftsController < ApplicationController
  include ActionView::Helpers::NumberHelper

  def index
    property_id = params[:property_id]
    if property_id.nil?
      property_id = params[:team_id]
    end
    @property = Property.find(property_id)
    
    authorize! :create_blue_shift, @property
    @blue_shifts = BlueShift.where(property: @property)
      .order("created_on DESC")
  end
  
  def show
    @blue_shift = BlueShift.find(params[:id])
    @due_date = @blue_shift.latest_fix_by_date()

    if @blue_shift.archived && @blue_shift.initial_archived_date
      @is_archived_current = true
    else
      @is_archived_current = false
    end

    setup_show_view
    puts "initial_archived_status = #{@blue_shift.initial_archived_status}"
    puts "archived_status = #{@blue_shift.archived_status}"
    puts "archive_edit_user = #{@blue_shift.archive_edit_user}"
    puts "archive_edit_date = #{@blue_shift.archive_edit_date}"
  end
  
  def new
    property_id = params[:property_id]
    if property_id.nil?
      property_id = params[:team_id]
    end
    @property = Property.find(property_id)
    
    authorize! :create_blue_shift, @property
  
    @blue_shift = BlueShift.new(user: current_user)
    @blue_shift.property = @property
    set_todays_date_to_today()
    @current_metric = get_current_metric()
    @current_metric_id = @current_metric.id

    # Default values
    @blue_shift.people_problem = true
    @blue_shift.product_problem = true
    @blue_shift.people_problem_fix_by = Date.today + 2.weeks
    @blue_shift.product_problem_fix_by = Date.today + 2.weeks
    @blue_shift.need_help_marketing_problem = false
    @blue_shift.need_help_capital_problem = false

    # Set Trigger values
    set_blueshift_triggers()
    set_metrics_names_causing_blue_shift()

    # Last Survey (in days)
    setup_last_survey_data()

    set_maint_blueshift_html

    set_dates_for_agent_sales_rollup_table(Date.today)

    # Set CoStar Market Occupancy
    set_costar_market_occupancy()

    # Set reviewed, if current_user is the TRM
    if current_user.is_a_team_lead
      @blue_shift.reviewed = true
    end
  end
    
  def create
    property_id = params[:property_id]
    if property_id.nil?
      property_id = params[:team_id]
    end
    @property = Property.find(property_id)
    
    authorize! :create_blue_shift, @property
    
    @blue_shift = BlueShift.new(blue_shift_params)
    @blue_shift.metric = get_current_metric()
    
    @blue_shift.property = @property
    @blue_shift.user = current_user
      
    set_blueshift_triggers()
    set_people_problem()
    set_product_problem()
    set_pricing_problem()
    set_need_help()
    
    assign_images
    if @blue_shift.save
      @property.blue_shift_status = "pending"
      @property.current_blue_shift = @blue_shift
      @property.save!

      # Send bluebot message to #rent-algorithm thread, including user that created blueshift.
      if @blue_shift.pricing_problem  == true
        send_pricing_problem_message(on_update: false, changed_to_approved: false, changed_to_denied: false, changed_to_approved_cond: false)
      end

      redirect_to root_path, notice: "BlueShift has been created."
    else
      set_todays_date_to_today()
      @current_metric = get_current_metric()
      set_metrics_names_causing_blue_shift()
      set_maint_blueshift_html()
      set_dates_for_agent_sales_rollup_table(Date.today)
      set_costar_market_occupancy()
      render 'new'
    end
    
  end
  
  def update
    @blue_shift = BlueShift.find(params[:id])
    @property = @blue_shift.property    
    
    # Used by update date alert
    @blue_shift.current_user = current_user

    blue_shift_had_pricing_problem = false
    if @blue_shift.pricing_problem == true
      blue_shift_had_pricing_problem = true
    end

    blue_shift_previous_pricing_problem_fix = @blue_shift.pricing_problem_fix
    blue_shift_previous_pricing_problem_approved = @blue_shift.pricing_problem_approved
    blue_shift_previous_pricing_problem_denied = @blue_shift.pricing_problem_denied
    blue_shift_previous_pricing_problem_approved_cond = @blue_shift.pricing_problem_approved_cond
    
    if can? :add_blue_shift_problem, @blue_shift, :people_problem
      set_people_problem
    end

    if can? :add_blue_shift_problem, @blue_shift, :product_problem
      set_product_problem
    end
    
    if can?(:add_blue_shift_problem, @blue_shift, :pricing_problem)
      set_pricing_problem()
      if @blue_shift.pricing_problem_images.count == 0
        assign_images
      end
    end

    if params[:blue_shift][:people_problem_fix_results].present?
      @blue_shift.people_problem_fix_results = params[:blue_shift][:people_problem_fix_results]
    end

    if params[:blue_shift][:product_problem_fix_results].present?
      @blue_shift.product_problem_fix_results = params[:blue_shift][:product_problem_fix_results]
    end

    if can? :edit, @blue_shift
      if params[:blue_shift][:people_problem_fix_by].present?
        @blue_shift.people_problem_fix_by = 
          Date.strptime(params[:blue_shift][:people_problem_fix_by], "%m/%d/%Y") 
      end
      
      if params[:blue_shift][:product_problem_fix_by].present?
        @blue_shift.product_problem_fix_by = 
          Date.strptime(params[:blue_shift][:product_problem_fix_by], "%m/%d/%Y") 
      end
      
      if params[:blue_shift][:pricing_problem_fix_by].present?
        @blue_shift.pricing_problem_fix_by = 
          Date.strptime(params[:blue_shift][:pricing_problem_fix_by], "%m/%d/%Y") 
      end
    end

    if can? :edit_reviewed, @blue_shift
      if params[:blue_shift][:reviewed].present?
        @blue_shift.reviewed = params[:blue_shift][:reviewed]
      end
      if params[:blue_shift][:pricing_problem_denied].present?
        @blue_shift.pricing_problem_denied = params[:blue_shift][:pricing_problem_denied]
      end
      if params[:blue_shift][:pricing_problem_approved].present?
        @blue_shift.pricing_problem_approved = params[:blue_shift][:pricing_problem_approved]
      end
      if params[:blue_shift][:pricing_problem_approved_cond].present?
        @blue_shift.pricing_problem_approved_cond = params[:blue_shift][:pricing_problem_approved_cond]
      end
      if params[:blue_shift][:pricing_problem_approved_cond_text].present?
        @blue_shift.pricing_problem_approved_cond_text = params[:blue_shift][:pricing_problem_approved_cond_text]
      end
    end

    if can? :edit_need_help_reviewed, @blue_shift
      if params[:blue_shift][:need_help_marketing_problem_marketing_reviewed].present?
        @blue_shift.need_help_marketing_problem_marketing_reviewed = params[:blue_shift][:need_help_marketing_problem_marketing_reviewed]
      end
      if params[:blue_shift][:need_help_capital_problem_maintenance_reviewed].present?
        @blue_shift.need_help_capital_problem_maintenance_reviewed = params[:blue_shift][:need_help_capital_problem_maintenance_reviewed]
      end
      if params[:blue_shift][:need_help_capital_problem_asset_management_reviewed].present?
        @blue_shift.need_help_capital_problem_asset_management_reviewed = params[:blue_shift][:need_help_capital_problem_asset_management_reviewed]
      end
    end
    
    if @blue_shift.save
      if !blue_shift_had_pricing_problem && @blue_shift.pricing_problem
        send_pricing_problem_message(on_update: true, changed_to_approved: false, changed_to_denied: false, changed_to_approved_cond: false)
      elsif @blue_shift.pricing_problem && @blue_shift.pricing_problem_fix != blue_shift_previous_pricing_problem_fix
        send_pricing_problem_message(on_update: true, changed_to_approved: false, changed_to_denied: false, changed_to_approved_cond: false)            
      elsif @blue_shift.pricing_problem && @blue_shift.pricing_problem_approved && !blue_shift_previous_pricing_problem_approved
        send_pricing_problem_message(on_update: true, changed_to_approved: true, changed_to_denied: false, changed_to_approved_cond: false)            
      elsif @blue_shift.pricing_problem && @blue_shift.pricing_problem_denied && !blue_shift_previous_pricing_problem_denied
        send_pricing_problem_message(on_update: true, changed_to_approved: false, changed_to_denied: true, changed_to_approved_cond: false)            
      elsif @blue_shift.pricing_problem && @blue_shift.pricing_problem_approved_cond && !blue_shift_previous_pricing_problem_approved_cond
        send_pricing_problem_message(on_update: true, changed_to_approved: false, changed_to_denied: false, changed_to_approved_cond: true)            
      end
      redirect_to root_path, notice: "BlueShift has been updated."
    else
      setup_show_view
      render 'show'
    end   
  end
  
  def archive
    @blue_shift = BlueShift.find(params[:id])
    authorize! :archive, @blue_shift
    
    if params[:blue_shift].nil? || params[:blue_shift][:archived_status].nil?
      archived_status = ''  # Nothing selected
    else
      archived_status = params[:blue_shift][:archived_status]
    end

    failure_reasons = ''
    if !@blue_shift.archived_failure_reasons.nil?
      failure_reasons = @blue_shift.archived_failure_reasons
    end
    if archived_status != "success"
      if !@blue_shift.archived
        failure_reasons = @blue_shift.auto_archive_failure_reasons_for_date(nil)
      elsif !@blue_shift.initial_archived_date.nil?
        failure_reasons = @blue_shift.auto_archive_failure_reasons_for_date(@blue_shift.initial_archived_date)
      end
    end

    archive = 
      BlueShifts::Commands::Archive.new(@blue_shift.id, archived_status, failure_reasons, current_user)
    archive.perform
    
    @blue_shift.reload
    
    if @blue_shift.archived
      redirect_to property_blue_shift_path(@blue_shift.property, @blue_shift), 
      notice: 'BlueShift has been archived.'
    else
      redirect_to property_blue_shift_path(@blue_shift.property, @blue_shift), 
      notice: 'BlueShift failed to be archived.'
    end
  end
  
  def destroy
    @blue_shift = BlueShift.find(params[:id])
    property = @blue_shift.property
    authorize! :delete, @blue_shift 

    @blue_shift.destroy
    
    redirect_to property_blue_shifts_path(property), 
       notice: 'BlueShift has been deleted'
  end
  
  private
  def blue_shift_params
    params.require(:blue_shift).permit(:need_help, 
    :need_help_marketing_problem, 
    :need_help_capital_problem, 
    :created_on, 
    :people_problem, 
    :no_people_problem_reason, 
    :no_people_problem_checked, 
    :people_problem_reason_all_office_staff, 
    :people_problem_reason_short_staffed, 
    :people_problem_reason_specific_people, 
    :people_problem_specific_people, 
    :people_problem_details, 
    :people_problem_fix, 
    :people_problem_fix_by, 
    :product_problem, 
    :product_problem_reason_curb_appeal, 
    :product_problem_reason_unit_make_ready, 
    :product_problem_reason_maintenance_staff, 
    :product_problem_specific_people, 
    :product_problem_details, 
    :product_problem_fix, 
    :product_problem_fix_by, 
    :pricing_problem, 
    :pricing_problem_approved, 
    :pricing_problem_denied, 
    :pricing_problem_approved_cond, 
    :pricing_problem_approved_cond_text, 
    :pricing_problem_fix, 
    :need_help_with, 
    :need_help_marketing_problem_marketing_reviewed, 
    :need_help_capital_problem_explained, 
    :need_help_capital_problem_maintenance_reviewed, 
    :need_help_capital_problem_asset_management_reviewed, 
    :reviewed)
  end
  
  def get_current_metric
    if @blue_shift && @blue_shift.archived && @blue_shift.initial_archived_date
      archived_day_metric = Metric.where(property: @property, date: @blue_shift.initial_archived_date).first
      if !archived_day_metric.nil?
        return archived_day_metric
      end
    end

    return Metric.where(property: @property).where(main_metrics_received: true).order("date DESC").first
  end

  def set_costar_market_occupancy
    costar_market_datum = CostarMarketDatum.where(property: @property).where("date <= ?", @current_metric.date).order("date DESC").first
    if !costar_market_datum.nil? && !costar_market_datum.submarket_percent_vacant.nil?
      @costar_market_occupancy = percent( 100 - (costar_market_datum.submarket_percent_vacant * 100) )
    else
      @costar_market_occupancy = 0
    end
  end
  
  def set_todays_date_to_today
    @todays_date = Time.now.to_date
  end
  
  def set_metrics_names_causing_blue_shift
    @x_rolling_days = Settings.blueshift_x_rolling_days.to_i

    date_for_current_or_archive = @blue_shift.latest_fix_by_date() + 1.day
    today = Date.today
    @is_archived_current
    if today < date_for_current_or_archive
      date_for_current_or_archive = today
    end

    @metrics_names_causing_blue_shift = []
    if !@blue_shift.physical_occupancy_triggered_value.nil?
      @metrics_names_causing_blue_shift << "<a class=\"red\" href=\"/blueshift_triggers.pdf\" target=\"_blank\">OCCUPANCY</a>".html_safe
    end
    
    if !@blue_shift.trending_average_daily_triggered_value.nil?
      @metrics_names_causing_blue_shift << "<a class=\"red\" href=\"/blueshift_triggers.pdf\" target=\"_blank\">TRENDING</a>".html_safe
    end

    # if @current_metric.cnoi_level == 4
    #   @metrics_names_causing_blue_shift << "CNOI".html_safe
    # end
    
    if !@blue_shift.basis_triggered_value.nil?
      @metrics_names_causing_blue_shift << "<a class=\"red\" href=\"/blueshift_triggers.pdf\" target=\"_blank\">BASIS</a>".html_safe
    end
  end

  def set_metric_averages(date)
    # for correct archive success logic, now locking date.
    if date > @blue_shift.latest_fix_by_date() + 1.day
      date = @blue_shift.latest_fix_by_date() + 1.day
    end
    
    latest_metrics = BlueShift.latest_metrics_for_success(@property, date)
    @current_or_archived_average_physical_occupancy_value = Metric.average_physical_occupancy(latest_metrics)
    @current_or_archived_average_trending_average_daily_value = Metric.average_trending_average_daily(latest_metrics)
    @current_or_archived_average_basis_value = Metric.average_basis(latest_metrics)
  end

  def set_blueshift_triggers
    value = Properties::Commands::CheckBlueShiftRequirement.blueshift_required_for_physical_occupancy_value?(@property, nil)
    @blue_shift.physical_occupancy_triggered_value = value != -1 ? value : nil
    value = Properties::Commands::CheckBlueShiftRequirement.blueshift_required_for_trending_average_daily_value?(@property, nil)
    @blue_shift.trending_average_daily_triggered_value = value != -1 ? value : nil
    value = Properties::Commands::CheckBlueShiftRequirement.blueshift_required_for_basis_value?(@property, nil)
    @blue_shift.basis_triggered_value = value != -1 ? value : nil
  end
  
  def set_people_problem
    @blue_shift.people_problem = params[:blue_shift][:people_problem]
    @blue_shift.people_problem_reason_all_office_staff = params[:blue_shift][:people_problem_reason_all_office_staff]
    @blue_shift.people_problem_reason_short_staffed = params[:blue_shift][:people_problem_reason_short_staffed]
    @blue_shift.people_problem_reason_specific_people = params[:blue_shift][:people_problem_reason_specific_people]
    @blue_shift.people_problem_specific_people = params[:blue_shift][:people_problem_specific_people]
    @blue_shift.people_problem_details = params[:blue_shift][:people_problem_details]

    if @blue_shift.people_problem == true
      @blue_shift.people_problem_fix = params[:blue_shift][:people_problem_fix]
      if params[:blue_shift][:people_problem_fix_by].present?
        @blue_shift.people_problem_fix_by = 
          Date.strptime(params[:blue_shift][:people_problem_fix_by], "%m/%d/%Y")
      end
    else
      @blue_shift.no_people_problem_reason = params[:blue_shift][:no_people_problem_reason] 
      @blue_shift.no_people_problem_checked = params[:blue_shift][:no_people_problem_checked]
    end 
  end
  
  def set_product_problem
    @blue_shift.product_problem = params[:blue_shift][:product_problem]
    @blue_shift.product_problem_reason_curb_appeal = params[:blue_shift][:product_problem_reason_curb_appeal]
    @blue_shift.product_problem_reason_unit_make_ready = params[:blue_shift][:product_problem_reason_unit_make_ready]
    @blue_shift.product_problem_reason_maintenance_staff = params[:blue_shift][:product_problem_reason_maintenance_staff]
    @blue_shift.product_problem_specific_people = params[:blue_shift][:product_problem_specific_people]
    @blue_shift.product_problem_details = params[:blue_shift][:product_problem_details]

    if @blue_shift.product_problem == true
      @blue_shift.product_problem_fix = params[:blue_shift][:product_problem_fix]
      if params[:blue_shift][:product_problem_fix_by].present?
        @blue_shift.product_problem_fix_by = 
          Date.strptime(params[:blue_shift][:product_problem_fix_by], "%m/%d/%Y")
      end
    end    
  end
  
  def set_pricing_problem
    if !params[:blue_shift][:pricing_problem].nil? # If not set, keep as-is
      @blue_shift.pricing_problem = params[:blue_shift][:pricing_problem]
    end

    if @blue_shift.pricing_problem  == true
      @blue_shift.pricing_problem_fix = params[:blue_shift][:pricing_problem_fix]
      if params[:blue_shift][:pricing_problem_fix_by].present?
        @blue_shift.pricing_problem_fix_by = 
          Date.strptime(params[:blue_shift][:pricing_problem_fix_by], "%m/%d/%Y")
      end
    end    
  end

  def set_need_help
    if !params[:blue_shift][:need_help].nil? # If not set, keep as-is
      @blue_shift.need_help = params[:blue_shift][:need_help]
    end

    if !params[:blue_shift][:need_help_marketing_problem].nil? # If not set, keep as-is
      @blue_shift.need_help_marketing_problem = params[:blue_shift][:need_help_marketing_problem]
    end

    if !params[:blue_shift][:need_help_capital_problem].nil? # If not set, keep as-is
      @blue_shift.need_help_capital_problem = params[:blue_shift][:need_help_capital_problem]
    end

    if params[:blue_shift][:need_help]
      @blue_shift.need_help_with = params[:blue_shift][:need_help_with]
    end

    if params[:blue_shift][:need_help_capital_problem]
      @blue_shift.need_help_capital_problem_explained = params[:blue_shift][:need_help_capital_problem_explained]
    end  
  end
  
  def assign_images 
    i = 0
    while i < 1000
      if params[:blue_shift]["pricing_problem_image_#{i}"].present?
        path = params[:blue_shift]["pricing_problem_image_#{i}"]
        caption = params[:blue_shift]["pricing_problem_image_caption_#{i}"]
        @blue_shift.pricing_problem_images << Image.new(path: path, caption: caption)
        i += 1
      else
        break
      end
    end
  end
  
  def setup_show_view
    @form_disabled = true
    property_id = params[:property_id]
    if property_id.nil?
      property_id = params[:team_id]
    end
    @property = Property.find(property_id)

    authorize! :create_blue_shift, @property

    @todays_date = @blue_shift.created_on
    @current_metric = @blue_shift.metric
    @latest_metric = get_current_metric()
    set_metrics_names_causing_blue_shift()
    set_metric_averages(@latest_metric.date)
    
    user_property = UserProperty.where(property: @property, user: current_user).first_or_initialize
    if user_property.maint_blue_shift_status.nil?
      user_property.maint_blue_shift_status = "none"
    end
    user_property.blue_shift_status = "viewed"
    user_property.save!
    
    commontator_thread_show(@blue_shift)
    
    @audits = @blue_shift.audits.union(Audited::Audit.where(auditable_type: @blue_shift.comment_thread.class.name, auditable_id: @blue_shift.comment_thread.id))

    if @blue_shift.people_problem_comment_thread.present?
      @audits = @audits.union(Audited::Audit.where(auditable_type: @blue_shift.people_problem_comment_thread.class.name, auditable_id: @blue_shift.people_problem_comment_thread.id))
    end  
    
    if @blue_shift.product_problem_comment_thread.present?
      @audits = @audits.union(Audited::Audit.where(auditable_type: @blue_shift.product_problem_comment_thread.class.name, auditable_id: @blue_shift.product_problem_comment_thread.id))

    end  
    
    if @blue_shift.pricing_problem_comment_thread.present?
      @audits = @audits.union(Audited::Audit.where(auditable_type: @blue_shift.pricing_problem_comment_thread.class.name, auditable_id: @blue_shift.pricing_problem_comment_thread.id))
    end  
    
    if @blue_shift.need_help_comment_thread.present?
      @audits = @audits.union(Audited::Audit.where(auditable_type: @blue_shift.need_help_comment_thread.class.name, auditable_id: @blue_shift.need_help_comment_thread.id))
    end  
      
    @audits = @audits.order("created_at DESC")    

    @show_pricing_problem_fix_by = !@blue_shift.pricing_problem_fix_by.nil? 

    @unlock_people_problem_fix_results = false
    if !@blue_shift.people_problem_fix_by.nil? && Date.today >= @blue_shift.people_problem_fix_by
      @unlock_people_problem_fix_results = true
    end
    @unlock_product_problem_fix_results = false
    if !@blue_shift.product_problem_fix_by.nil? && Date.today >= @blue_shift.product_problem_fix_by
      @unlock_product_problem_fix_results = true
    end

    set_previous_people_problem_fix()
    set_previous_product_problem_fix()

    setup_last_survey_data()
    set_maint_blueshift_html
    set_dates_for_agent_sales_rollup_table(@blue_shift.created_on)
    set_costar_market_occupancy()
  end

  def set_previous_people_problem_fix
    @previous_people_problem_plan_to_fix = nil
    prev_blue_shift = BlueShift.where(property: @property).where("created_on < ?", @blue_shift.created_on).order("created_on DESC").first
    if !prev_blue_shift.nil? && !prev_blue_shift.archived_status.nil? &&
      prev_blue_shift.archived_status == "failure" && prev_blue_shift.created_on >= @blue_shift.created_on - 3.weeks
      @previous_people_problem_plan_to_fix = prev_blue_shift.people_problem_fix
    end
  end

  def set_previous_product_problem_fix
    @previous_product_problem_plan_to_fix = nil
    prev_blue_shift = BlueShift.where(property: @property).where("created_on < ?", @blue_shift.created_on).order("created_on DESC").first
    if !prev_blue_shift.nil? && !prev_blue_shift.archived_status.nil? &&
      prev_blue_shift.archived_status == "failure" && prev_blue_shift.created_on >= @blue_shift.created_on - 3.weeks
      @previous_product_problem_plan_to_fix = prev_blue_shift.product_problem_fix
    end
  end
  
  def set_dates_for_agent_sales_rollup_table(date)
    # For Blueshift Agent Sales Rollup Table, with dates reversed
    dates = (1..12).to_a.map{ |d| (date + 1.day - d.months).end_of_month }
    @date_names = dates.collect do |d|
      d.strftime("%b")
    end
  end

  def days_since_last_survey_level(average_days)
    if average_days < 0
      return nil
    end

    return 1 if average_days <= 7
    return 2 if average_days <= 14
    return 3 if average_days <= 28
    return 6 if average_days > 28 
    
    return nil
  end

  def set_maint_blueshift_html
    if @property.maint_blue_shift_status == "required" 
      if can?(:create_maint_blue_shift, @property)
        @maint_blueshift_html = view_context.link_to('Create Maintenence Blueshift', new_property_maint_blue_shift_path(property_id: @property.id) , class: 'flash flash_red', data: { turbolinks: false })
      end
    elsif @property.maint_blue_shift_status == "pending"
      user_property = UserProperty.where(user: current_user, property: @property).first
      blue_shift = @property.current_maint_blue_shift
      
      if @property.current_maint_blue_shift.present? and @property.current_maint_blue_shift.any_fix_by_date_expired? 
        css_class = "flash_row_red"
      # Has been viewed
      elsif user_property.present? and user_property.maint_blue_shift_status == "viewed"
        css_class = "blue"
      # Needs help with has not been viewed
      elsif blue_shift.need_help_with_no_selected_problems?
        css_class = "flash_row_blue"
      # Has not been viewed
      else
        css_class = "flash flash_blue"
      end

      @maint_blueshift_html = view_context.link_to('View Maintenance Blueshift', property_maint_blue_shift_path(@property.id, blue_shift), class: css_class, data: { turbolinks: false })

    else
      if can?(:create_maint_blue_shift, @property)
        @maint_blueshift_html = view_context.link_to('Create Maintenance Blueshift', new_property_maint_blue_shift_path(property_id: @property.id), data: { turbolinks: false })
      end
    end  
  end

  # Send bluebot message to #rent-algorithm thread, including user that created blueshift.
  def send_pricing_problem_message(on_update:, changed_to_approved:, changed_to_denied:, changed_to_approved_cond:)
    if @blue_shift.pricing_problem  == true
      created_updated_message = "A new blueshift for *`#{@property.code}`* has been created:"
      if on_update
        created_updated_message = "A blueshift for *`#{@property.code}`* has been updated:"        
      end
      root_url = "#{request.protocol}#{request.host}"
      blueshift_url = "#{root_url}/properties/#{@property.id}/blue_shifts/#{@blue_shift.id}"

      mentions = ""
      
      mentions += @property.property_manager_mentions(current_user)

      trm_mention = @property.talent_resource_manager_mention(current_user)
      if trm_mention != ""
        mentions += " #{trm_mention}"
      end

      if @blue_shift.pricing_problem_approved == true
        mentions = "@algorithm#{mentions}"
      end

      message = ""
      if changed_to_approved == true
        message = "#{mentions}: #{created_updated_message}\n#{blueshift_url}\n\n<@#{current_user.slack_username}> *approved* the pricing problem fix:\n\n```#{@blue_shift.pricing_problem_fix}```"
      elsif changed_to_denied == true
        message = "#{mentions}: #{created_updated_message}\n#{blueshift_url}\n\n<@#{current_user.slack_username}> *denied* the pricing problem fix:\n\n```#{@blue_shift.pricing_problem_fix}```"
      elsif changed_to_approved_cond == true
        message = "#{mentions}: #{created_updated_message}\n#{blueshift_url}\n\n<@#{current_user.slack_username}> *approved w/ conditions* the pricing problem fix:\n\n```#{@blue_shift.pricing_problem_fix}```\n\nTRM Conditions:\n```#{@blue_shift.pricing_problem_approved_cond_text}```"
      else
        message = "#{mentions}: #{created_updated_message}\n#{blueshift_url}\n\n<@#{current_user.slack_username}> wrote about a pricing problem:\n\n```#{@blue_shift.pricing_problem_fix}```"

        if @blue_shift.pricing_problem_approved == true
          message = "#{message}\n\nCurrently, the pricing problem fix is set to *TRM Approved*."
        elsif @blue_shift.pricing_problem_denied == true
          message = "#{message}\n\nCurrently, the pricing problem fix is set to *TRM Denied*."
        else  
          message = "#{message}\n\nCurrently, the pricing problem fix is NOT *TRM Approved / Denied* yet."
        end
      end

      puts message

      send_slack_alert('#rent-algorithm', message)
    end
  end

  def send_slack_alert(slack_channel, message)

    # slack_target = "@channel"
    # slack_channel = update_slack_channel(property.slack_channel)

    # message = "A BlueShift is required for #{property.code}. #{slack_target}" 
    # Remove @, if test
    if slack_channel.include? 'test'
      message.sub! '@', ''
    end 
    send_alert = 
      Alerts::Commands::SendBlueShiftSlackMessage.new(message, slack_channel)
    Job.create(send_alert)      
  end

  def update_slack_channel(slack_channel)
    channel = ''
    unless Rails.env.test?
      if Settings.slack_test_mode == 'enabled'
        channel = slack_channel.sub 'prop', 'test'
      else
        channel = slack_channel.sub 'test', 'prop'
      end   
    end

    return channel
  end

  def setup_last_survey_data
    rent_change_reasons = RentChangeReason.where(property: @current_metric.property, date: @current_metric.date)
    no_survey_days = 50 * 365 # just a high enough number to know there was no survey done
    @average_days_since_last_survey = -1.0 # no data value
    units_with_no_survey_done_array = []
    # loop through array to find average, but note that no survey was done for array of unit types
    num_of_surveyed_units = 0
    total_last_survey_days_ago = 0
    rent_change_reasons.each do |rcr|
      unless rcr.last_survey_days_ago.nil?
        if rcr.last_survey_days_ago >= no_survey_days
          units_with_no_survey_done_array << rcr.unit_type_code
        else
          num_of_surveyed_units += 1
          total_last_survey_days_ago += rcr.last_survey_days_ago
          @average_days_since_last_survey = total_last_survey_days_ago.to_f / num_of_surveyed_units.to_f
        end
      end
    end

    @units_with_no_survey_done = units_with_no_survey_done_array.join(", ")
    @average_days_since_last_survey_level = days_since_last_survey_level(@average_days_since_last_survey)
  end

  def percent(value)
    number_to_percentage(value, precision: 0, strip_insignificant_zeros: true)
  end

end
