class Cobalt.CostarMarketDataShowController
  
  initialize: () ->
    @getParams()
    import_date = $('#costar_market_data_form_import_date').children("option:selected").val()
    @baseDataTableUrl = "/costar_market_data.json?costar_market_data_form[import_date]=#{import_date}"

    @propertySortCycle = 0
    
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
        { orderable: true, targets: -1 },
        { targets: 0, sClass: "properties_sort_field" }
      ]
      initComplete: () =>
        @customizeSorting()
      drawCallback: () =>
      fnServerParams: (aoData) =>
        aoData['property_sort_cycle'] = @propertySortCycle % 3

  
    @dataTable = $("#costar_market_data_table").DataTable(options)
    
    
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

  customizeSorting: () ->
    $(".properties_sort_field").unbind('click')
    
    $(document).on "click", '.properties_sort_field.sorting_desc', () =>
      @sortProperties('asc')

    $(document).on "click", '.properties_sort_field.sorting_asc', () =>
      @sortProperties('desc')

  sortProperties: (sortDirection) ->
    @propertySortCycle += 1
    @dataTable.column(0).order(sortDirection).draw()
      
