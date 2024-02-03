require 'test_helper'
 
class MetricChartsControllerTest < ActionController::TestCase
  def setup
    @metric = metrics(:one)
  end
  
  test "returns chart data" do
    get :index, metric_id: @metric.id, metric_attribute: "cnoi"
    results = JSON.parse(response.body)
      
    assert_equal Metric.where(property: @metric.property)
      .where("date <= ?", @metric.date).where.not("cnoi" => nil).count, results.count
      
    results.each do |result|      
      assert_not_nil result["y"]
      assert_not_nil result["x"]
      assert_not_nil result["moving_average"]
      assert_not_nil result["budget"]
    end
  end
end
