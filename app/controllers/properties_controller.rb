class PropertiesController < ApplicationController
  before_action :set_property, only: [:show, :edit, :update, :destroy, :latest_inspection_partial, :bluesky_stats_partial, :latest_inspection_and_deficients_partial]
  before_action :set_javascript_controller_name
  load_and_authorize_resource except: [:send_test_message_to_slack, :latest_inspection_partial, :bluesky_stats_partial, :latest_inspection_and_deficients_partial]

  # GET /properties
  # GET /properties.json
  def index
    filter = params[:filter]
    if filter == 'manager_strikes'
      @properties = Property.properties.where(active: true).where("manager_strikes > 0").order(:code)
    elsif filter == 'team'
      @properties = Property.properties.where(active: true).order(:code)
      @properties = @properties.sort_by { |p| p.team ? p.team.code : '' }
    elsif filter == 'city'
      @properties = Property.properties.where(active: true).order(:city)
    elsif filter == 'state'
      @properties = Property.properties.where(active: true).order(:state)
    else
      @properties = Property.properties
      @properties = @properties.sort_by { |p| p.active ? "#{Property.get_code_position(p.code, p.type)}#{p.code}" : "#{Property.get_code_position(p.code, p.type) + 3}#{p.code}" }
    end
  end

  # GET /properties/1
  # GET /properties/1.json
  def show
  end

  # GET /properties/1/edit
  def edit
  end


  # PATCH/PUT /properties/1
  # PATCH/PUT /properties/1.json
  def update
    puts property_params    
    respond_to do |format|
      if @property.update(property_params)
        notice_text = 'Property was successfully updated.'
        if property_params[:type] == 'Team'
          @property = Team.find(@property.id) # We changed to type Team
          notice_text = 'Team was successfully updated.'
        end
        format.html { redirect_to @property, notice: notice_text }
        format.json { render :show, status: :ok, location: @property }
      else
        format.html { render :edit }
        format.json { render json: @property.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def send_test_message_to_slack
    authorize! :update, Property
    
    @property = Property.find(params[:id])
    send_alert = 
      Alerts::Commands::SendSlackMessage.new("Test message sent from Cobalt.", 
      @property.slack_channel)
    Job.create(send_alert)
    
    flash[:notice] = "Slack message sent."
    render :show
  end

  def latest_inspection_partial
    if @property.should_update_latest_inspection?
      @created_on = Date.parse(params[:created_on]) rescue nil
      @property.update_latest_inspection(@created_on)
    end
    respond_to do |format|
      format.js
    end
  end

  def latest_inspection_and_deficients_partial
    @property.update_latest_inspection(nil)
    respond_to do |format|
      format.js
    end
  end

  def bluesky_stats_partial
    @people_bluesky_unclaimed_leads_status = "no_alert"
    @people_bluesky_leadspeed_status = "no_alert"
    @people_bluesky_tenacity_status = "no_alert"
    @people_bluesky_unclaimed_leads = "..."
    @people_bluesky_leadspeed = "..."
    @people_bluesky_tenacity = "..."

    @on_date = Date.parse(params[:on_date]) rescue nil
    @property.update_bluesky_stats(@on_date)

    if @property.bluesky_data.present?
      stats = @property.bluesky_data[:stats]
      error = @property.bluesky_data[:error]
      if error.present?
        @people_bluesky_unclaimed_leads_status = "alert"
        @people_bluesky_leadspeed_status = "alert"
        @people_bluesky_tenacity_status = "alert"
        @people_bluesky_unclaimed_leads = "err"
        @people_bluesky_leadspeed = "err"
        @people_bluesky_tenacity = "err"    
      elsif stats.present?
        @people_bluesky_unclaimed_leads = stats["UnclaimedLeadsNow"].present? ? stats["UnclaimedLeadsNow"] : "?"
        @people_bluesky_leadspeed = stats["LeadSpeed30"].present? ? stats["LeadSpeed30"] : "?" 
        if stats["Tenacity30"].to_i >= 1 && stats["Tenacity30"].to_i <= 10
          @people_bluesky_tenacity = "#{stats["Tenacity30"]}/10"
        elsif stats["Tenacity30"].present?
          @people_bluesky_tenacity = "#{stats["Tenacity30"]}"
        else  
          @people_bluesky_tenacity = "?"
        end

        if stats["UnclaimedLeadsNow"].to_i > 0
          @people_bluesky_unclaimed_leads_status = "alert"
        end
        if stats["LeadSpeed30"] == "C" || stats["LeadSpeed30"] == "D" || stats["LeadSpeed30"] == "F"
          @people_bluesky_leadspeed_status = "alert"
        end
        if stats["Tenacity30"].to_i >= 1 && stats["Tenacity30"].to_i <= 7
          @people_bluesky_tenacity_status = "alert"
        end
      end
    end

    respond_to do |format|
      format.js
    end
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_property
      @property = Property.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def property_params
      if params[:property][:is_a_team]
        params[:property][:type] = 'Team'
        params[:property][:team_id] = 0 # A Team will never have a team
        params[:property].delete(:is_a_team)
      end 
      if @property.code == Property.portfolio_code()
        params[:property][:team_id] = 0 # Portfolio will never have a team
      end
      params.require(:property).permit(:slack_channel, :manager_strikes, :sparkle_blshift_pm_templ_name, :type, :team_id, :active, :city, :state, :logo, :image, :num_of_units)
    end

    def set_javascript_controller_name
      @javascript_controller_name = controller_name.camelize + 'Controller'
    end
end
