require 'httparty'

class MaintBlueShiftsController < ApplicationController
  
  def index
    property_id = params[:property_id]
    if property_id.nil?
      property_id = params[:team_id]
    end
    @property = Property.find(property_id)
    
    authorize! :create_blue_shift, @property
    @blue_shifts = MaintBlueShift.where(property: @property)
      .order("created_on DESC")
  end
  
  def show
    @blue_shift = MaintBlueShift.find(params[:id])
    @due_date = @blue_shift.latest_fix_by_date()

    if @blue_shift.archived && @blue_shift.initial_archived_date
      @is_archived_current = true
    else
      @is_archived_current = false
    end

    setup_show_view
  end
  
  def new
    property_id = params[:property_id]
    if property_id.nil?
      property_id = params[:team_id]
    end
    @property = Property.find(property_id)
    
    authorize! :create_maint_blue_shift, @property
  
    @blue_shift = MaintBlueShift.new(user: current_user)
    @blue_shift.property = @property
    set_todays_date_to_today
    @current_metric = current_metric
    @current_metric_id = current_metric.id
    set_metrics_names_causing_blue_shift

    # Default values
    @blue_shift.people_problem = true
    @blue_shift.people_problem_fix_by = Date.today + 2.weeks
    @blue_shift.vendor_problem_fix_by = Date.today + 2.weeks
    @blue_shift.parts_problem_fix_by = Date.today + 2.weeks

    # @blue_shift.product_problem = true

    # Last Survey (in days)
    # setup_last_survey_data

    set_property_blueshift_html
    @show_image_uploads_for_parts = false

    # Set reviewed, if current_user is the TRS
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
    
    authorize! :create_maint_blue_shift, @property
    
    @blue_shift = MaintBlueShift.new(blue_shift_params)
    @blue_shift.metric = current_metric
    
    @blue_shift.property = @property
    @blue_shift.user = current_user
      
    set_people_problem  
    set_vendor_problem
    set_parts_problem
    
    if params[:maint_blue_shift][:need_help]
      @blue_shift.need_help_with = params[:maint_blue_shift][:need_help_with]
    end
    
    assign_images
    if @blue_shift.save
      @property.maint_blue_shift_status = "pending"
      @property.current_maint_blue_shift = @blue_shift
      @property.save!

      # Send bluebot message to #rent-algorithm thread, including user that created blueshift.
      # if @blue_shift.pricing_problem  == true
      #   send_pricing_problem_message(false)
      # end

      redirect_to root_path, notice: "BlueShift has been created."
    else
      set_todays_date_to_today
      @current_metric = current_metric
      set_metrics_names_causing_blue_shift
      set_property_blueshift_html 
      @show_image_uploads_for_parts = false     
      render 'new'
    end
    
  end
  
  def update
    @blue_shift = MaintBlueShift.find(params[:id])
    @property = @blue_shift.property    
    
    # Used by update date alert
    @blue_shift.current_user = current_user

    # blue_shift_had_pricing_problem = false
    # if @blue_shift.pricing_problem == true
    #   blue_shift_had_pricing_problem = true
    # end

    # blue_shift_previous_pricing_problem_fix = @blue_shift.pricing_problem_fix
    
    if can? :add_maint_blue_shift_problem, @blue_shift, :people_problem
      set_people_problem
    end

    if can? :add_maint_blue_shift_problem, @blue_shift, :vendor_problem
      set_vendor_problem
    end
    
    if can?(:add_maint_blue_shift_problem, @blue_shift, :parts_problem)
      set_parts_problem
      if @blue_shift.parts_problem_images.count == 0
        assign_images
      end
    end
    
    if can? :edit, @blue_shift

      if params[:maint_blue_shift][:people_problem_fix_by].present?
        @blue_shift.people_problem_fix_by = 
          Date.strptime(params[:maint_blue_shift][:people_problem_fix_by], "%m/%d/%Y") 
      end
      
      if params[:maint_blue_shift][:vendor_problem_fix_by].present?
        @blue_shift.vendor_problem_fix_by = 
          Date.strptime(params[:maint_blue_shift][:vendor_problem_fix_by], "%m/%d/%Y") 
      end
      
      if params[:maint_blue_shift][:parts_problem_fix_by].present?
        @blue_shift.parts_problem_fix_by = 
          Date.strptime(params[:maint_blue_shift][:parts_problem_fix_by], "%m/%d/%Y") 
      end
    end
    
    if @blue_shift.save
      # if !blue_shift_had_pricing_problem && @blue_shift.pricing_problem
      #   send_pricing_problem_message(true)
      # elsif @blue_shift.pricing_problem && @blue_shift.pricing_problem_fix != blue_shift_previous_pricing_problem_fix
      #   send_pricing_problem_message(true)            
      # end
      redirect_to root_path, notice: "BlueShift has been updated."
    else
      setup_show_view
      render 'show'
    end 
  end
  
  def archive
    @blue_shift = MaintBlueShift.find(params[:id])
    authorize! :archive, @blue_shift

    if params[:maint_blue_shift].nil? || params[:maint_blue_shift][:archived_status].nil?
      archived_status = ''  # Nothing selected
    else
      archived_status = params[:maint_blue_shift][:archived_status]
    end
    
    archive = MaintBlueShifts::Commands::Archive.new(@blue_shift.id, archived_status, current_user)
    archive.perform
    
    @blue_shift.reload
    
    if @blue_shift.archived
      redirect_to property_maint_blue_shift_path(@blue_shift.property, @blue_shift), 
      notice: 'BlueShift has been archived.'
    else
      redirect_to property_maint_blue_shift_path(@blue_shift.property, @blue_shift), 
      notice: 'BlueShift failed to be archived.'
    end
  end
  
  def destroy
    @blue_shift = MaintBlueShift.find(params[:id])
    property = @blue_shift.property
    authorize! :delete, @blue_shift 

    @blue_shift.destroy
    
    redirect_to property_maint_blue_shifts_path(property), 
       notice: 'BlueShift has been deleted'
  end
  
  private
  def blue_shift_params
    params.require(:maint_blue_shift).permit(:need_help, :created_on)
  end
  
  def current_metric
    if @blue_shift && @blue_shift.archived && @blue_shift.initial_archived_date
      return Metric.where(property: @property, date: @blue_shift.initial_archived_date).first
    end
    
    return Metric.where(property: @property).order("date DESC").first
  end
  
  def set_todays_date_to_today
    @todays_date = Time.now.to_date
  end
  
  def set_metrics_names_causing_blue_shift
    @metrics_names_causing_blue_shift = []
    if @current_metric.maintenance_percentage_ready_over_vacant_level > 2
      @metrics_names_causing_blue_shift << "MAKE READY".html_safe
    end
    
    if @current_metric.maintenance_open_wos_level > 2
      @metrics_names_causing_blue_shift << "WORK ORDERS".html_safe
    end
      
  end
  
  def set_people_problem
    @blue_shift.people_problem = params[:maint_blue_shift][:people_problem]
    if @blue_shift.people_problem == true
      @blue_shift.people_problem_fix = params[:maint_blue_shift][:people_problem_fix]
      if params[:maint_blue_shift][:people_problem_fix_by].present?
        @blue_shift.people_problem_fix_by = 
          Date.strptime(params[:maint_blue_shift][:people_problem_fix_by], "%m/%d/%Y")
      end
    end
  end
  
  def set_vendor_problem
    @blue_shift.vendor_problem = params[:maint_blue_shift][:vendor_problem]
    if @blue_shift.vendor_problem == true
      @blue_shift.vendor_problem_fix = params[:maint_blue_shift][:vendor_problem_fix]
      if params[:maint_blue_shift][:vendor_problem_fix_by].present?
        @blue_shift.vendor_problem_fix_by = 
          Date.strptime(params[:maint_blue_shift][:vendor_problem_fix_by], "%m/%d/%Y")
      end
    end    
  end
  
  def set_parts_problem
    if !params[:maint_blue_shift][:parts_problem].nil? # If not set, keep as-is
      @blue_shift.parts_problem = params[:maint_blue_shift][:parts_problem]
    end

    if @blue_shift.parts_problem  == true
      @blue_shift.parts_problem_fix = params[:maint_blue_shift][:parts_problem_fix]
      if params[:maint_blue_shift][:parts_problem_fix_by].present?
        @blue_shift.parts_problem_fix_by = 
          Date.strptime(params[:maint_blue_shift][:parts_problem_fix_by], "%m/%d/%Y")
      end
    end    
  end
  
  def assign_images 
    i = 0
    while i < 1000
      if params[:maint_blue_shift]["parts_problem_image_#{i}"].present?
        path = params[:maint_blue_shift]["parts_problem_image_#{i}"]
        caption = params[:maint_blue_shift]["parts_problem_image_caption_#{i}"]
        @blue_shift.parts_problem_images << Image.new(path: path, caption: caption)
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
    
    authorize! :create_maint_blue_shift, @property

    @todays_date = @blue_shift.created_on
    @current_metric = @blue_shift.metric
    @latest_metric = current_metric
    set_metrics_names_causing_blue_shift
    
    user_property = UserProperty.where(property: @property, user: current_user).first_or_initialize
    if user_property.blue_shift_status.nil?
      user_property.blue_shift_status = "none"
    end
    user_property.maint_blue_shift_status = "viewed"
    user_property.save!
    
    commontator_thread_show(@blue_shift)
    
    @audits = @blue_shift.audits.union(Audited::Audit.where(auditable_type: @blue_shift.comment_thread.class.name, auditable_id: @blue_shift.comment_thread.id))
    
    if @blue_shift.people_problem_comment_thread.present?
      @audits = @audits.union(Audited::Audit.where(auditable_type: @blue_shift.people_problem_comment_thread.class.name, auditable_id: @blue_shift.people_problem_comment_thread.id))
    end  
    
    if @blue_shift.vendor_problem_comment_thread.present?
      @audits = @audits.union(Audited::Audit.where(auditable_type: @blue_shift.vendor_problem_comment_thread.class.name, auditable_id: @blue_shift.vendor_problem_comment_thread.id))
    end  
    
    if @blue_shift.parts_problem_comment_thread.present?
      @audits = @audits.union(Audited::Audit.where(auditable_type: @blue_shift.parts_problem_comment_thread.class.name, auditable_id: @blue_shift.parts_problem_comment_thread.id))
    end  
    
    if @blue_shift.need_help_comment_thread.present?
      @audits = @audits.union(Audited::Audit.where(auditable_type: @blue_shift.need_help_comment_thread.class.name, auditable_id: @blue_shift.need_help_comment_thread.id))
    end  
      
    @audits = @audits.order("created_at DESC")    
    
    # setup_last_survey_data
    set_property_blueshift_html
    @show_image_uploads_for_parts = false
  end

  # Send bluebot message to #rent-algorithm thread, including user that created blueshift.
  # def send_pricing_problem_message(update)
  #   if @blue_shift.pricing_problem  == true
  #     created_updated_message = "A new blueshift for `#{@property.code}` has been created:"
  #     if update
  #       created_updated_message = "A blueshift for `#{@property.code}` has been updated:"        
  #     end
  #     root_url = "#{request.protocol}#{request.host}"
  #     blueshift_url = "#{root_url}/properties/#{@property.id}/maint_blue_shifts/#{@blue_shift.id}"
  #     message = "@algorithm: #{created_updated_message}\n#{blueshift_url}\n\n@#{current_user.slack_username} wrote about a pricing problem:\n\n```#{@blue_shift.pricing_problem_fix}```"          
  #     property_manager = @property.property_manager_user
  #     if !property_manager.nil?
  #       if property_manager.id != current_user.id
  #         message = "@algorithm @#{property_manager.slack_username}: #{created_updated_message}\n#{blueshift_url}\n\n@#{current_user.slack_username} wrote about a pricing problem:\n\n```#{@blue_shift.pricing_problem_fix}```"                                            
  #       end
  #     else
  #       message += "\n\n `Note: No Property Manager set for this property, in Cobalt.`"
  #     end

  #     send_slack_alert('#rent-algorithm', message)
  #   end
  # end

  def set_property_blueshift_html
    if @property.blue_shift_status == "required" 
      if can?(:create_blue_shift, @property)
        @property_blueshift_html = view_context.link_to('Create Property Blueshift', new_property_blue_shift_path(property_id: @property.id) , class: 'flash flash_red', data: { turbolinks: false })
      end
    elsif @property.blue_shift_status == "pending"
      user_property = UserProperty.where(user: current_user, property: @property).first
      blue_shift = @property.current_blue_shift
      
      if @property.current_blue_shift.present? and @property.current_blue_shift.any_fix_by_date_expired? 
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

      @property_blueshift_html = view_context.link_to('View Property Blueshift', property_blue_shift_path(@property.id, blue_shift), class: css_class, data: { turbolinks: false })

    else
      if can?(:create_blue_shift, @property)
        @property_blueshift_html = view_context.link_to('Create Property Blueshift', new_property_blue_shift_path(property_id: @property.id), data: { turbolinks: false })
      end
    end  
  end

  # def send_slack_alert(slack_channel, message)

  #   # slack_target = "@channel"
  #   # slack_channel = update_slack_channel(property.slack_channel)

  #   # message = "A BlueShift is required for #{property.code}. #{slack_target}" 
  #   # Remove @, if test
  #   if slack_channel.include? 'test'
  #     message.sub! '@', ''
  #   end 
  #   send_alert = 
  #     Alerts::Commands::SendBlueShiftSlackMessage.new(message, slack_channel)
  #   Job.create(send_alert)      
  # end

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

end
