class Cobalt.RentChangeReasonsShowController
  
  initialize: () ->
    @getParams()
    metric_id = @params["metric_id"]
    @baseDataTableUrl = "/rent_change_reasons.json?metric_id=#{metric_id}"
    
    @createDataTable() 

    @setupUnitTypeRentHistory()   
      
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
  
    @dataTable = $("#rent_change_reasons_table").DataTable(options)
    
    
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
  
  setupUnitTypeRentHistory: () ->
    $(document).off 'click', '#rent_change_reasons tbody td span[data-unit-type-rent-history]'
    $(document).on 'click', '#rent_change_reasons tbody td span[data-unit-type-rent-history]', (e) =>
      $target = $(e.target)
      rentChangeReasonId = $target.parents("tr").find(".rent_change_reason_id").val()
      window.open "/unit_type_rent_history?rent_change_reason_id=#{rentChangeReasonId}", "_self"

    

      
