class ConversionsForAgentsChartsController < ApplicationController
  before_action :set_data, only: [:show]
  before_action :set_charts_data, only: [:show]

  # GET /conversions_for_agents_charts?agent_id=<id>&date=<date>...
  def show
    respond_to do |format|
      format.html
      format.json { render json: @charts_data.to_json }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_data
    cfa_id = params[:cfa_id]
    portfolio = params[:portfolio]
    team_id = params[:team_id]
    @cfa_id_data = ''
    @portfolio_data = ''
    @team_id_data = ''

    if !cfa_id.nil?
      cfa = ConversionsForAgent.find(cfa_id)
      @cfa_agent = cfa.agent
      @cfa_id_data = "cfa_id=#{cfa_id}"
    elsif portfolio != nil
      @cfa_agent = 'Portfolio'
      @portfolio_data = "portfolio=#{portfolio}"
    elsif team_id != nil
      team = Property.find(team_id)
      @cfa_agent = team.code
      @team_id_data = "team_id=#{team_id}"
    end
    @date = params[:date]

    @full_size = params[:full_size] == "1"

    # Set ALL for default
    @cfa_attributes = ConversionsForAgentsChartData.valid_cfa_attributes().sort

    $custom_attributes = params[:custom_attributes]
    if $custom_attributes == 'prospects_30days'
      @cfa_attributes = ['prospects_30days']
    end
  end

  def set_charts_data
    @charts_data = []
    @cfa_attributes.each do |attr| 
      if @full_size
        @charts_data.append("#{@cfa_id_data} #{@portfolio_data} #{@team_id_data} date=#{@date} agent_name=#{@cfa_agent} data_metric=#{attr} full_size=1")
      else
        @charts_data.append("#{@cfa_id_data} #{@portfolio_data} #{@team_id_data} date=#{@date} agent_name=#{@cfa_agent} data_metric=#{attr}")
      end
    end
  end
  
end
