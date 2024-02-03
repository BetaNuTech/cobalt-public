require 'httparty'

class TrmBlueShiftsController < ApplicationController
  include ActionView::Helpers::NumberHelper

  def index
    property_id = params[:property_id]
    if property_id.nil?
      property_id = params[:team_id]
    end
    @property = Property.find(property_id)
    
    authorize! :create_trm_blue_shift, @property
    @trm_blue_shifts = TrmBlueShift.where(property: @property)
      .order("created_on DESC")
  end
  
  def show
    @trm_blue_shift = TrmBlueShift.find(params[:id])
    @due_date = @trm_blue_shift.latest_fix_by_date()

    if @trm_blue_shift.archived && @trm_blue_shift.initial_archived_date
      @is_archived_current = true
    else
      @is_archived_current = false
    end

    setup_show_view
    puts "initial_archived_status = #{@trm_blue_shift.initial_archived_status}"
    puts "archived_status = #{@trm_blue_shift.archived_status}"
    puts "archive_edit_user = #{@trm_blue_shift.archive_edit_user}"
    puts "archive_edit_date = #{@trm_blue_shift.archive_edit_date}"
  end
  
  def new
    property_id = params[:property_id]
    if property_id.nil?
      property_id = params[:team_id]
    end
    @property = Property.find(property_id)
    
    authorize! :create_trm_blue_shift, @property
  
    @trm_blue_shift = TrmBlueShift.new(user: current_user)
    @trm_blue_shift.property = @property
    set_todays_date_to_today()
    @current_metric = get_current_metric()
    @current_metric_id = @current_metric.id

    # Default values
    @trm_blue_shift.manager_problem = true
    @trm_blue_shift.manager_problem_fix_by = Date.today + 3.weeks
    @trm_blue_shift.marketing_problem_fix_by = Date.today + 3.weeks

    # Set Trigger values
    set_triggers_for_trm_blue_shift()

    # Pull Leads Data
    set_leads_data()
  end
    
  def create
    property_id = params[:property_id]
    @property = Property.find(property_id)
    
    authorize! :create_trm_blue_shift, @property
    
    @trm_blue_shift = TrmBlueShift.new(trm_blue_shift_params)
    @trm_blue_shift.metric = get_current_metric()
    
    @trm_blue_shift.property = @property
    @trm_blue_shift.user = current_user
      
    set_manager_problem()
    set_market_problem()
    set_marketing_problem()
    set_capital_problem()
    
    if @trm_blue_shift.save
      @property.trm_blue_shift_status = "pending"
      @property.current_trm_blue_shift = @trm_blue_shift
      @property.save!

      redirect_to root_path, notice: "TRM BlueShift has been created."
    else
      set_todays_date_to_today()
      @current_metric = get_current_metric()
      set_triggers_for_trm_blue_shift()
      render 'new'
    end
    
  end
  
  def update
    @trm_blue_shift = TrmBlueShift.find(params[:id])
    @property = @trm_blue_shift.property    
    
    # Used by update date alert
    @trm_blue_shift.current_user = current_user
    
    if can? :add_trm_blue_shift_problem, @trm_blue_shift, :manager_problem
      set_manager_problem()
    end

    if can? :add_trm_blue_shift_problem, @trm_blue_shift, :market_problem
      set_market_problem()
    end
    
    if can?(:add_blue_shift_problem, @trm_blue_shift, :marketing_problem)
      set_marketing_problem()
    end

    if can?(:add_blue_shift_problem, @trm_blue_shift, :capital_problem)
      set_capital_problem()
    end

    if params[:trm_blue_shift][:manager_problem_results].present?
      @trm_blue_shift.manager_problem_results = params[:trm_blue_shift][:manager_problem_results]
    end

    if can? :edit, @trm_blue_shift
      if params[:trm_blue_shift][:manager_problem_fix_by].present?
        @trm_blue_shift.manager_problem_fix_by = 
          Date.strptime(params[:trm_blue_shift][:manager_problem_fix_by], "%m/%d/%Y") 
      end

      if params[:trm_blue_shift][:marketing_problem_fix_by].present?
        @trm_blue_shift.marketing_problem_fix_by = 
          Date.strptime(params[:trm_blue_shift][:marketing_problem_fix_by], "%m/%d/%Y") 
      end
    end

    if can? :edit_vp_reviewed, @trm_blue_shift
      if params[:trm_blue_shift][:vp_reviewed].present?
        @trm_blue_shift.vp_reviewed = params[:trm_blue_shift][:vp_reviewed]
      end
    end
    
    if @trm_blue_shift.save
      redirect_to root_path, notice: "TRM BlueShift has been updated."
    else
      setup_show_view
      render 'show'
    end   
  end
  
  def archive
    @trm_blue_shift = TrmBlueShift.find(params[:id])
    authorize! :archive, @trm_blue_shift
    
    if params[:trm_blue_shift].nil? || params[:trm_blue_shift][:archived_status].nil?
      archived_status = ''  # Nothing selected
    else
      archived_status = params[:trm_blue_shift][:archived_status]
    end

    archive = 
      TrmBlueShifts::Commands::Archive.new(@trm_blue_shift.id, archived_status, current_user)
    archive.perform
    
    @trm_blue_shift.reload
    
    if @trm_blue_shift.archived
      redirect_to property_trm_blue_shift_path(@trm_blue_shift.property, @trm_blue_shift), 
      notice: 'TRM BlueShift has been archived.'
    else
      redirect_to property_trm_blue_shift_path(@trm_blue_shift.property, @trm_blue_shift), 
      notice: 'TRM BlueShift failed to be archived.'
    end
  end
  
  def destroy
    @trm_blue_shift = TrmBlueShift.find(params[:id])
    property = @trm_blue_shift.property
    authorize! :delete, @trm_blue_shift 

    @trm_blue_shift.destroy
    
    redirect_to property_trm_blue_shifts_path(property), 
       notice: 'TRM BlueShift has been deleted'
  end
  
  private
  def trm_blue_shift_params
    params.require(:trm_blue_shift).permit(:created_on)
  end
  
  def get_current_metric
    if @trm_blue_shift && @trm_blue_shift.archived && @trm_blue_shift.initial_archived_date
      archived_day_metric = Metric.where(property: @property, date: @trm_blue_shift.initial_archived_date).first
      if !archived_day_metric.nil?
        return archived_day_metric
      end
    end

    return Metric.where(property: @property).where(main_metrics_received: true).order("date DESC").first
  end
  
  def set_todays_date_to_today
    @todays_date = Time.now.to_date
  end
  
  def set_triggers_for_trm_blue_shift
    if !@current_metric.nil?
      trigger_metrics = @current_metric.trm_blueshift_trigger_reasons()
      @triggers_causing_trm_blue_shift = trigger_metrics.join("<br>")
    end

    if !@latest_metric.nil?
      trigger_metrics = @latest_metric.trm_blueshift_trigger_reasons()
      @latest_triggers_trm_blue_shift = trigger_metrics.join("<br>")
    end
  end
  
  def set_manager_problem
    @trm_blue_shift.manager_problem = params[:trm_blue_shift][:manager_problem]

    if @trm_blue_shift.manager_problem == true
      @trm_blue_shift.manager_problem_details = params[:trm_blue_shift][:manager_problem_details]
      @trm_blue_shift.manager_problem_fix = params[:trm_blue_shift][:manager_problem_fix]
      if params[:trm_blue_shift][:manager_problem_fix_by].present?
        @trm_blue_shift.manager_problem_fix_by = 
          Date.strptime(params[:trm_blue_shift][:manager_problem_fix_by], "%m/%d/%Y")
      end
    end 
  end

  def set_market_problem
    @trm_blue_shift.market_problem = params[:trm_blue_shift][:market_problem]

    if @trm_blue_shift.market_problem == true
      @trm_blue_shift.market_problem_details = params[:trm_blue_shift][:market_problem_details]
    end 
  end

  def set_marketing_problem
    @trm_blue_shift.marketing_problem = params[:trm_blue_shift][:marketing_problem]

    if @trm_blue_shift.marketing_problem == true
      @trm_blue_shift.marketing_problem_details = params[:trm_blue_shift][:marketing_problem_details]
      @trm_blue_shift.marketing_problem_fix = params[:trm_blue_shift][:marketing_problem_fix]
      if params[:trm_blue_shift][:marketing_problem_fix_by].present?
        @trm_blue_shift.marketing_problem_fix_by = 
          Date.strptime(params[:trm_blue_shift][:marketing_problem_fix_by], "%m/%d/%Y")
      end
    end 
  end

  def set_capital_problem
    @trm_blue_shift.capital_problem = params[:trm_blue_shift][:capital_problem]

    if @trm_blue_shift.capital_problem == true
      @trm_blue_shift.capital_problem_details = params[:trm_blue_shift][:capital_problem_details]
    end 
  end
  
  def setup_show_view
    @form_disabled = true
    property_id = params[:property_id]
    if property_id.nil?
      property_id = params[:team_id]
    end
    @property = Property.find(property_id)

    authorize! :create_trm_blue_shift, @property

    @todays_date = @trm_blue_shift.created_on
    @current_metric = @trm_blue_shift.metric
    @latest_metric = get_current_metric()
    set_triggers_for_trm_blue_shift()
    
    user_property = UserProperty.where(property: @property, user: current_user).first_or_initialize
    user_property.trm_blue_shift_status = "viewed"
    user_property.save!
    
    commontator_thread_show(@trm_blue_shift)
    
    @audits = @trm_blue_shift.audits.union(Audited::Audit.where(auditable_type: @blue_shift.comment_thread.class.name, auditable_id: @blue_shift.comment_thread.id))
    
    if @trm_blue_shift.manager_problem_comment_thread.present?
      @audits = @audits.union(Audited::Audit.where(auditable_type: @blue_shift.manager_problem_comment_thread.class.name, auditable_id: @blue_shift.manager_problem_comment_thread.id))
    end  
    
    if @trm_blue_shift.market_problem_comment_thread.present?
      @audits = @audits.union(Audited::Audit.where(auditable_type: @blue_shift.market_problem_comment_thread.class.name, auditable_id: @blue_shift.market_problem_comment_thread.id))
    end  
    
    if @trm_blue_shift.marketing_problem_comment_thread.present?
      @audits = @audits.union(Audited::Audit.where(auditable_type: @blue_shift.marketing_problem_comment_thread.class.name, auditable_id: @blue_shift.marketing_problem_comment_thread.id))
    end  
    
    if @trm_blue_shift.capital_problem_comment_thread.present?
      @audits = @audits.union(Audited::Audit.where(auditable_type: @blue_shift.capital_problem_comment_thread.class.name, auditable_id: @blue_shift.capital_problem_comment_thread.id))
    end  
      
    @audits = @audits.order("created_at DESC")    

    @unlock_manager_problem_results = false
    if !@trm_blue_shift.manager_problem_fix_by.nil? && Date.today >= @trm_blue_shift.manager_problem_fix_by
      @unlock_manager_problem_results = true
    end

    # Pull Leads Data
    set_leads_data()
  end

  def send_slack_alert(message)
    slack_channel = TrmBlueShift.trm_blueshift_channel()

    # Remove @, if test
    if slack_channel.include? 'test'
      message.sub! '@', ''
    end 
    send_alert = 
      Alerts::Commands::SendCorpBlueBotSlackMessage.new(message, slack_channel)
    Job.create(send_alert)      
  end

  def set_leads_data
    if !@trm_blue_shift.created_on.nil?
      cfp = ConversionsForAgent.where(date: @trm_blue_shift.created_on, agent: @property.code).first
      if !cfp.nil?
        metrics = cfp.property_metrics()
        @num_of_leads_needed = number(metrics[:num_of_leads_needed])
        @bluesky_leads = number(cfp.druid_prospects_30days)
      end
      if @trm_blue_shift.created_on != Date.today
        cfp = ConversionsForAgent.where(date: Date.today, agent: @property.code).first
        if !cfp.nil?
          metrics = cfp.property_metrics()
          @latest_num_of_leads_needed = number(metrics[:num_of_leads_needed])
          @latest_bluesky_leads = number(cfp.druid_prospects_30days)
        end
      end
    else
      cfp = ConversionsForAgent.where(date: Date.today, agent: @property.code).first
      if !cfp.nil?
        metrics = cfp.property_metrics()
        @num_of_leads_needed = number(metrics[:num_of_leads_needed])
        @bluesky_leads = number(cfp.druid_prospects_30days)
      end
    end
  end

  def percent(value)
    number_to_percentage(value, precision: 0, strip_insignificant_zeros: true)
  end

  def number(value)
    number_with_precision(value, precision: 1, strip_insignificant_zeros: true)  
  end

end
