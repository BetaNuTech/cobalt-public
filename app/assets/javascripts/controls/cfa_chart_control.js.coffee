class Cobalt.CFAChartControl
  
  constructor: () ->
    
    
  initialize: () ->

  create: (url, target, title, width, height) ->
    padding = 50
    paddingBottom = 76
    
    d3.json url, (data) =>

      svg = d3.select(target)
        .data(data)
        .append("svg")
        .attr("width", width)
        .attr("height", height)

      # Axis  
      minDate = new Date(data[0].x)
      maxDate = new Date(data[data.length-1].x)
      
      yMax = d3.max data, (d) ->
        if typeof(data[0]["budget"]) != 'undefined'
          return Math.max(d.y, d.budget)
        else if typeof(data[0]["num_of_leads_needed"]) != 'undefined'
          max = Math.max(d.y, d.num_of_leads_needed)
          if typeof(data[0]["druid_prospects_30days"]) != 'undefined'
            return Math.max(max, d.druid_prospects_30days)
          return max
        else
          return Math.max(d.y)

        
      yMin = d3.min data, (d) ->
        if typeof(data[0]["budget"]) != 'undefined'
          return Math.min(d.y, d.budget)
        else if typeof(data[0]["num_of_leads_needed"]) != 'undefined'
          min = Math.min(d.y, d.num_of_leads_needed)
          if typeof(data[0]["druid_prospects_30days"]) != 'undefined'
            min = Math.min(min, d.druid_prospects_30days)            
          if min > 0
            return min 
          else
            return Math.min(d.y)
        else
          return Math.min(d.y)
      
          
      x = d3.scaleTime().domain([minDate, maxDate]).range([padding, width - padding])   
      y = d3.scaleLinear().domain([yMin, yMax]).range([height - paddingBottom, padding])

      dateFormat = d3.timeFormat("%m/%d/%y")
      
      xAxis = d3.axisBottom()
        .scale(x)
        .tickFormat(dateFormat);
        
      yAxis = d3.axisLeft()
        .scale(y)
        
      svg.append("g")
        .attr("class", "xaxis axis")  
        .attr("transform", "translate(0, #{height - paddingBottom})")
        .call(xAxis);     
        
      svg.append("g")
        .attr("class", "yaxis axis")
        .attr("transform", "translate(#{padding}, 0)")
        .call(yAxis);  
        
      # rotate text on x axis
      # See http://bl.ocks.org/phoebebright/3061203
      svg.selectAll(".xaxis text")  # select all the text elements for the xaxis
        .attr "transform", (d) -> 
          return "translate(#{this.getBBox().height*-2}, #{this.getBBox().height + 8})rotate(-45)"

      
      # Budget Line
      unless typeof(data[0]["budget"]) == 'undefined'
        line = d3.line()
          .x (d) ->
            return x(new Date(d.x))
          .y (d) ->
            return y(d.budget)         
        
        svg.append('svg:path')
          .attr('class', 'line')
          .attr "d", (d) -> 
            return line(data)    
          .attr('stroke', 'red')
          .attr('stroke-width', 2)
          .attr('fill', 'none')

      # Num of leads needed (for conversions_for_agents charts) Line
      unless typeof(data[0]["num_of_leads_needed"]) == 'undefined'
        line = d3.line()
          .x (d) ->
            return x(new Date(d.x))
          .y (d) ->
            return y(d.num_of_leads_needed)         
        
        svg.append('svg:path')
          .attr('class', 'line')
          .attr "d", (d) -> 
            return line(data)    
          .attr('stroke', 'red')
          .attr('stroke-width', 2)
          .attr('fill', 'none')

      # Druid leads (for conversions_for_agents charts) Line
      unless typeof(data[0]["druid_prospects_30days"]) == 'undefined'
        line = d3.line()
          .x (d) ->
            return x(new Date(d.x))
          .y (d) ->
            return y(d.druid_prospects_30days)         
        
        svg.append('svg:path')
          .attr('class', 'line')
          .attr "d", (d) -> 
            return line(data)    
          .attr('stroke', 'lightblue')
          .attr('stroke-width', 2)
          .attr('fill', 'none')
    
      #moving average line
      movingAverageLine = d3.line()
        .x (d) ->
          return x(new Date(d.x))
        .y (d) ->
          return y(d.moving_average)     
          
      svg.append('svg:path')
        .attr('class', 'line')
        .attr "d", (d) -> 
          return movingAverageLine(data)    
        .attr('stroke', 'green')
        .attr('stroke-width', 2)
        .attr('fill', 'none')
          
    
      # Line
      line = d3.line()
        .x (d) ->
          return x(new Date(d.x))
        .y (d) ->
          return y(d.y)         
      
      svg.append('svg:path')
        .attr('class', 'line')
        .attr "d", (d) -> 
          return line(data)    
        .attr('stroke', 'blue')
        .attr('stroke-width', 2)
        .attr('fill', 'none')
        
        

      # Title  
      svg.append("text")
        .attr("x", (width / 2))             
        .attr("y", 0 + (padding / 2))
        .attr("class", "chart_title")    
        .attr("text-anchor", "middle")  
        # .style("font-size", "16px") 
        .style("text-decoration", "underline")  
        .text(title);
        
      # Legend
      
      svg.append("text")
        .attr("x", (width/2) - 160)
        .attr("y", height - (paddingBottom/2) + 28)
        .attr("class", "legend")    
        .style("fill", "blue")
        .text("Value")
        
      svg.append("text")
        .attr("x", (width/2) - 80)
        .attr("y", height - (paddingBottom/2) + 28)
        .attr("class", "legend")    
        .style("fill", "green")
        .text("30 Day Moving Average")
        
      unless typeof(data[0]["budget"]) == 'undefined'  
        svg.append("text")
          .attr("x", (width/2) + 116)
          .attr("y", height - (paddingBottom/2) + 28)
          .attr("class", "legend")    
          .style("fill", "red")
          .text("Budget")

      unless typeof(data[0]["num_of_leads_needed"]) == 'undefined'  
        svg.append("text")
          .attr("x", (width/2) + 80)
          .attr("y", height - (paddingBottom/2) + 28)
          .attr("class", "legend")    
          .style("fill", "red")
          .text("Leads Needed")
      
      unless typeof(data[0]["druid_prospects_30days"]) == 'undefined'  
        svg.append("text")
          .attr("x", (width/2) + 180)
          .attr("y", height - (paddingBottom/2) + 28)
          .attr("class", "legend")    
          .style("fill", "lightblue")
          .text("BlueSky")
