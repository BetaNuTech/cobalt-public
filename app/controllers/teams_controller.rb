class TeamsController < ApplicationController
  before_action :set_team, only: [:show, :edit, :update, :destroy]
  before_action :set_javascript_controller_name
  load_and_authorize_resource except: [:send_test_message_to_slack]

  # GET /teams
  # GET /teams.json
  def index
    filter = params[:filter]
    @teams = Team.order(:code)
    @teams = @teams.sort_by { |t| t.active ? Property.get_code_position(t.code, t.type) : Property.get_code_position(t.code, t.type) + 3 }
  end

  # GET /teams/1
  # GET /teams/1.json
  def show
  end

  # GET /teams/1/edit
  def edit
  end


  # PATCH/PUT /teams/1
  # PATCH/PUT /teams/1.json
  def update
    respond_to do |format|
      if @team.update(team_params)
        notice_text = 'Team was successfully updated.'
        if team_params[:type] == 'Property'
          @team = Property.find(@team.id) # We changed to type Property
          notice_text = 'Property was successfully updated.'
        end
        format.html { redirect_to @team, notice: notice_text }
        format.json { render :show, status: :ok, location: @team }
      else
        format.html { render :edit }
        format.json { render json: @team.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def send_test_message_to_slack
    authorize! :update, Property
    
    @team = Team.find(params[:id])
    send_alert = 
      Alerts::Commands::SendSlackMessage.new("Test message sent from Cobalt.", 
      @team.slack_channel)
    Job.create(send_alert)
    
    flash[:notice] = "Slack message sent."
    render :show
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_team
      @team = Team.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def team_params 
      if params[:team][:is_a_property]
        params[:team][:type] = 'Property'
        params[:team].delete(:is_a_property)
      end       
      params.require(:team).permit(:slack_channel, :type, :active, :logo)
    end

    def set_javascript_controller_name
      @javascript_controller_name = controller_name.camelize + 'Controller'
    end
end
