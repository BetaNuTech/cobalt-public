class Cobalt.ConversionsForAgentsChartsShowController
  
  initialize: () ->    
    @drawGraphs()  
  
  drawGraphs: () ->
    $(window).load ->
      $('.cfa_graph_container').each (index, e) ->
        chartControl = new Cobalt.CFAChartControl()

        width = 330
        height = 280

        full_size = $(e).attr("full_size")
        if full_size == '1'
          width = 900
          height = 400

        $(e).width(width)
        $(e).height(height)
        $(e).addClass("graph_#{index}")
                    
        cfaId = $(e).attr("cfa_id")
        date = $(e).attr("date")
        portfolio = $(e).attr("portfolio")
        team_id = $(e).attr("team_id")
        agentName = $(e).attr("agent_name")
        cfaAttribute = $(e).attr("data_metric")
        title = "#{agentName}: #{cfaAttribute}"
        
        console.log("CFAChartControl.create")
        if cfaId
          chartControl.create("/cfa_charts.json?cfa_id=#{cfaId}&cfa_attribute=#{cfaAttribute}",
          ".graph_#{index}", title, width, height)
        else if date
          if portfolio  
            chartControl.create("/cfa_charts.json?date=#{date}&portfolio=1&cfa_attribute=#{cfaAttribute}",
            ".graph_#{index}", title, width, height)
          else if team_id
            chartControl.create("/cfa_charts.json?date=#{date}&team_id=#{team_id}&cfa_attribute=#{cfaAttribute}",
            ".graph_#{index}", title, width, height)


