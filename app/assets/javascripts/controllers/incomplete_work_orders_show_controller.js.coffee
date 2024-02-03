class Cobalt.IncompleteWorkOrdersShowController
  
  initialize: () ->
    @getParams()
    property_id = @params["property_id"]
    date = @params["date"]
    @baseDataTableUrl = "/incomplete_work_orders.json?property_id=#{property_id}&date=#{date}"
    
    @createDataTable() 
    @setupComplianceIssues()
      
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
        { orderable: true, targets: -1 }
      ]
      initComplete: () =>
      drawCallback: () =>
      fnServerParams: (aoData) =>
  
    @dataTable = $("#incomplete_work_orders_table").DataTable(options)
    
    
    $(window).resize () =>
      height = @getAvailableContentHeight()
      $(".dataTables_scrollBody").css("max-height", "#{height}px")
    
  setupComplianceIssues: () ->
    $(document).off 'click', 'span.compliance_issue'
    $(document).on 'click', 'span.compliance_issue', (e) =>
      $target = $(e.target)
      propertyId = $target.parents("tr").find(".property_id").val()
      date = $target.parents("tr").find(".date").val()
      window.open "/compliance_issues?property_id=#{propertyId}&date=#{date}", "_self"

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

    

      
