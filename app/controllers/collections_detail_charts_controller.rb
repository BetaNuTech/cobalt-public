class CollectionsDetailChartsController < ApplicationController

  def index
    detail = CollectionsDetail.find(params[:collections_detail_id])
    attribute = params[:attribute]

    data = CollectionsDetailChartData.collect_data(detail, attribute)
    
    render json: data
  end

end
