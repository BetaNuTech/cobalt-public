class MetricAttributeChartsController < ApplicationController
  before_action :set_metrics, only: [:show]

  # POST /metric_attribute_charts/:attribute
  # POST /metric_attribute_charts/:attribute.json
  def show
    @metric_attribute = params[:attribute]
    set_charts_data()

    respond_to do |format|
      format.html
      format.json { render json: @charts_data.to_json }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_metrics
    if current_user.get_team_id.nil?
      @team_codes = Team.where(active: true).order("code ASC").pluck('code')
    else
      @team_codes = []
    end

    # team_code selected by non-team user
    if params[:team_code]
      @team_selected = Property.where(code: params[:team_code]).first
      @team_codes = @team_codes.sort_by { |code| @team_selected.code == code ? 0 : 1 }
    end

    @metrics = []
    @property_names = []
    
    @team_id = current_user.get_team_id

    @date = params[:metric_attribute_charts_date]

    if @team_selected && !current_user.view_all_properties
      @property_names.append(@team_selected.code)
      if @date
        metric = Metric.where(property_id: @team_selected.id, date: @date).first
        if metric
          @metrics.append(metric) 
        end
      else
        @metrics.append(Metric.where(property_id: @team_selected.id).order("date DESC").first)
      end
  
      Property.properties.where(active: true, team_id: @team_selected.id).order("code ASC").each do |p|
        @property_names.append(p.code)
        if @date
          metric = Metric.where(property: p, date: @date).first
          if metric
            @metrics.append(metric) 
          end
        else
          @metrics.append(Metric.where(property: p).order("date DESC").first)
        end
      end
    elsif @team_id && !current_user.view_all_properties
      user_team = Team.find(@team_id)
      @property_names.append(user_team.code)
      if @date
        metric = Metric.where(property_id: @team_id, date: @date).first
        if metric
          @metrics.append(metric) 
        end
      else
        @metrics.append(Metric.where(property_id: @team_id).order("date DESC").first)
      end
  
      Property.properties.where(active: true, team_id: @team_id).order("code ASC").each do |p|
        @property_names.append(p.code)
        if @date
          metric = Metric.where(property: p, date: @date).first
          if metric
            @metrics.append(metric) 
          end
        else
          @metrics.append(Metric.where(property: p).order("date DESC").first)
        end
      end
    else
      portfolio_prop = Property.where(code: Property.portfolio_code()).first
      if portfolio_prop
        @property_names.append(portfolio_prop.code)
        if @date
          metric = Metric.where(property: portfolio_prop, date: @date).first
          if metric
            @metrics.append(metric) 
          end
        else
          @metrics.append(Metric.where(property: portfolio_prop).order("date DESC").first)
        end
      end
  
      Property.teams.order("code ASC").each do |p|
        @property_names.append(p.code)
        if @date
          metric = Metric.where(property: p, date: @date).first
          if metric
            @metrics.append(metric) 
          end
        else
          @metrics.append(Metric.where(property: p).order("date DESC").first)
        end
      end
  
      Property.properties.where(active: true).where.not(code: Property.portfolio_code()).order("code ASC").each do |p|
        @property_names.append(p.code)
        if @date
          metric = Metric.where(property: p, date: @date).first
          if metric
            @metrics.append(metric) 
          end
        else
          @metrics.append(Metric.where(property: p).order("date DESC").first)
        end
      end
    end

  end

  def set_charts_data
    @charts_data = []
    @metrics.each_with_index do |metric, index|
      puts "metric_id=#{metric.id} data_metric=#{@metric_attribute}"
      # @charts_data.append(MetricChartData.collect_data(metric, @metric_attribute))
      @charts_data.append("metric_id=#{metric.id} data_metric=#{@metric_attribute} property_name=#{@property_names[index]}")
    end
  end

end

