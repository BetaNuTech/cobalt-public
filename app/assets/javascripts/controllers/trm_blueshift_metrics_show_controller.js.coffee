class Cobalt.TrmBlueshiftMetricsShowController
  
  initialize: () ->
    @getParams()
    team_id = @params["team_id"]
    @baseDataTableUrl = "/trm_blueshift_metrics.json?team_id=#{team_id}"
    
    @createDataTable() 

    @hideHUD()
    # @setupHUD()
      
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
        { targets: [0,1], visible: true }
      ]
      initComplete: () =>
      drawCallback: () =>
      fnServerParams: (aoData) =>
  
    @dataTable = $("#trm_blueshift_metrics_table").DataTable(options)
    
    
    $(window).resize () =>
      height = @getAvailableContentHeight()
      $(".dataTables_scrollBody").css("max-height", "#{height}px")
    
  
  getAvailableContentHeight: () ->
    tableHeaderHeight = 57
    heightAdjustment = 18
    
    height = $(window).outerHeight() - $("#header").height() - tableHeaderHeight - heightAdjustment
    return height

  setupHUD: () ->
    $(document).on 'click', '#trm_blueshift_metrics .property_name a'
    $(document).on 'click', '#trm_blueshift_metrics .property_name a', (e) =>
      @showHUD()
    
    $(document).off 'page:before-unload'
    $(document).on 'page:before-unload', (e) =>
      console.log '**************************** Turbolinks event *******************************'
      @hideHUD()

    window.pagehide = @hideHUD()

  showHUD: () ->
    console.log '**************************** HUD Shown *******************************'
    $("#hud").css("display", "block")

  hideHUD: () ->
    console.log '**************************** HUD Hidden *******************************'
    $("#hud").css("display", "none")
  
  getParams: () ->
    query = window.location.search.substring(1)
    raw_vars = query.split("&")

    @params = {}

    for v in raw_vars
      [key, val] = v.split("=")
      @params[key] = decodeURIComponent(val)
  

      
