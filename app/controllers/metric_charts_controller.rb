class MetricChartsController < ApplicationController

  def index
    metric = Metric.find(params[:metric_id])
    metric_attribute = params[:metric_attribute]

    metric_data = MetricChartData.collect_data(metric, metric_attribute)
    
    render json: metric_data
  end

end
