class Cobalt.MetricAttributeChartsShowController
  
  initialize: () ->    
    @drawMetricGraphs()

    @chartControl = new Cobalt.ChartControl()    
    @setupMetricGraphs()  
  
  drawMetricGraphs: () ->
    $(window).load ->
      $('.metric_graph_container').each (index, e) ->
        chartControl = new Cobalt.ChartControl()

        width = 330
        height = 280
        $(e).width(width)
        $(e).height(height)
        $(e).addClass("graph_#{index}")
                    
        metricId = $(e).attr("metric_id")
        propertyName = $(e).attr("property_name")
        metricAttribute = $(e).attr("data_metric")
        title = "#{propertyName}: #{metricAttribute}"
        
        chartControl.create("/metrics/#{metricId}/metric_charts.json?metric_attribute=#{metricAttribute}",
        ".graph_#{index}", title, width, height)

  setupMetricGraphs: () ->
    $('body').off 'click'
    $('body').on 'click', (e) =>
      if $(e.target).closest('.popup_metric_graph_container').length > 0
        $('.popup_metric_graph_container').remove()        
        return 
      else
        $('.popup_metric_graph_container').remove()        

    $(document).off 'click', '.metric_graph_container svg'
    $(document).on 'click', '.metric_graph_container svg', (e) =>
      $target = $(e.target)
      $graphContainer = $("<div class='popup_metric_graph_container'></div>")
      width = $(window).outerWidth() - ($(window).outerWidth() / 10)
      height = $(window).outerHeight() / 2
      $graphContainer.width(width)
      $graphContainer.height(height)
      
      $graphContainer.css("position", "fixed")
      $graphContainer.css("top", (2 * $(window).outerHeight() / 3) - (height/2))
      $graphContainer.css("left", ($(window).outerWidth() / 2) - (width/2))
      $target.after($graphContainer)
      
      metricId = $target.parents(".metric_graph_container").attr("metric_id")
      propertyName = $target.parents(".metric_graph_container").attr("property_name")
      metricAttribute = $target.parents(".metric_graph_container").attr("data_metric")
      title = "#{propertyName}: #{metricAttribute}"
      
      @chartControl.create("/metrics/#{metricId}/metric_charts.json?metric_attribute=#{metricAttribute}",
        ".popup_metric_graph_container", title, width, height)
