class Cobalt.ConversionsForAgentsShowController
  
  initialize: () ->
    @getParams()
    property_id = @params["property_id"]
    date = @params["date"]
    @baseDataTableUrl = "/conversions_for_agents.json?property_id=#{property_id}&date=#{date}"
    
    @createDataTable() 
      
  createDataTable: () ->
    options = 
      ajax: 
        url: @baseDataTableUrl
        type: 'get'
      ordering: true
      processing: true
      serverSide: true
      paging: false
      info: false
      searching: false
      order: [[ 0, "asc" ]]
      scrollY: "#{@getAvailableContentHeight()}px"
      scrollX: "true"
      scrollCollapse: true
      fixedColumns:
        leftColumns: 1
      columnDefs: [
        { targets: [0,1,2,3,4,5,6,7,8,9], visible: true }
      ]
      initComplete: () =>
      drawCallback: () =>
      fnServerParams: (aoData) =>
  
    @dataTable = $("#conversions_for_agents_table").DataTable(options)
    
    
    $(window).resize () =>
      height = @getAvailableContentHeight()
      $(".dataTables_scrollBody").css("max-height", "#{height}px")
    
  
  getAvailableContentHeight: () ->
    tableHeaderHeight = 57
    heightAdjustment = 18
    
    height = $(window).outerHeight() - $("#header").height() - tableHeaderHeight - heightAdjustment
    return height
  
  getParams: () ->
    query = window.location.search.substring(1)
    raw_vars = query.split("&")

    @params = {}

    for v in raw_vars
      [key, val] = v.split("=")
      @params[key] = decodeURIComponent(val)

    

      
