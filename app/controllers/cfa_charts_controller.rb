class CfaChartsController < ApplicationController

  def index
    cfa_attribute = params[:cfa_attribute]

    cfa_id = params[:cfa_id]
    if !cfa_id.nil?
      cfa = ConversionsForAgent.find(cfa_id)
      puts "Rendering chart data"
      chart_data = ConversionsForAgentsChartData.collect_data(cfa, cfa_attribute)
      render json: chart_data
    else
      date = params[:date]
      if !date.nil?
        portfolio = params[:portfolio]
        team_id = params[:team_id]
        if !portfolio.nil? && portfolio
          puts "Rendering Portfolio chart data"
          chart_data = ConversionsForAgentsChartData.portfolio_collect_data(date, cfa_attribute)
          render json: chart_data
        elsif !team_id.nil? && team_id != ''
          puts "Rendering Team chart data"
          chart_data = ConversionsForAgentsChartData.team_collect_data(date, team_id, cfa_attribute)
          render json: chart_data
        end
      end
    end
  end

end
