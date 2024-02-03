class Cobalt.ChartOverlayControl
  
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
        if typeof(data[0]["budget"]) == 'undefined'
          return Math.max(d.y)
        else
          return Math.max(d.y, d.budget)
        
      yMin = d3.min data, (d) ->
        if typeof(data[0]["budget"]) == 'undefined'
          return Math.min(d.y)
        else
          return Math.min(d.y, d.budget)
      
          
      x = d3.scaleTime().domain([minDate, maxDate]).range([padding, width - padding])   
      y = d3.scaleLinear().domain([yMin, yMax]).range([height - paddingBottom, padding])
        
      yAxis = d3.axisRight()
        .scale(y)  
        
      svg.append("g")
        .attr("class", "yaxis axis")
        .attr("transform", "translate(#{padding}, 0)")
        .call(yAxis);  
      
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
          .attr('stroke', 'FireBrick')
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
        .attr('stroke', 'MediumSeaGreen')
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
        .attr('stroke', 'DodgerBlue')
        .attr('stroke-width', 2)
        .attr('fill', 'none')
        
        

      # Title  
      svg.append("text")
        .attr("x", (width / 2))             
        .attr("y", 0 + (padding / 2) + 15)
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
