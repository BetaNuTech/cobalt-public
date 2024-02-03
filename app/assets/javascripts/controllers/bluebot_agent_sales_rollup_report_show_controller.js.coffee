class Cobalt.BluebotAgentSalesRollupReportShowController
  
  initialize: () ->
    end_month = $('#bluebot_rollup_report_form_end_month').children("option:selected").val()
    property_id = $('#property_id').val()
    @baseDataTableUrl = "/bluebot_agent_sales_rollup_report.json?property_id=#{property_id}&bluebot_rollup_report_form[end_month]=#{end_month}"
    
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
        { targets: 0, sClass: "agents_sort_field" },
        { targets: 1, sClass: "c0_sort_field" },
        { targets: 2, sClass: "c1_sort_field" },
        { targets: 3, sClass: "c2_sort_field" },
        { targets: 4, sClass: "c3_sort_field" },
        { targets: 5, sClass: "c4_sort_field" },
        { targets: 6, sClass: "c5_sort_field" },
        { targets: 7, sClass: "c6_sort_field" },
        { targets: 8, sClass: "c7_sort_field" },
        { targets: 9, sClass: "c8_sort_field" },
        { targets: 10, sClass: "c9_sort_field" },
        { targets: 11, sClass: "c10_sort_field" },
        { targets: 12, sClass: "c11_sort_field" },
        { targets: 13, sClass: "all_months_bar_sort_field" },
        { targets: 14, sClass: "all_months_sort_field" }
      ]
      initComplete: () =>
        @customizeSorting()
      drawCallback: () =>
      fnServerParams: (aoData) =>
  
    @dataTable = $("#bluebot_agent_sales_rollup_report_table").DataTable(options)
    
    
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
    $(".agents_sort_field").unbind('click')
    $(".c0_sort_field").unbind('click')
    $(".c1_sort_field").unbind('click')
    $(".c2_sort_field").unbind('click')
    $(".c3_sort_field").unbind('click')
    $(".c4_sort_field").unbind('click')
    $(".c5_sort_field").unbind('click')
    $(".c6_sort_field").unbind('click')
    $(".c7_sort_field").unbind('click')
    $(".c8_sort_field").unbind('click')
    $(".c9_sort_field").unbind('click')
    $(".c10_sort_field").unbind('click')
    $(".c11_sort_field").unbind('click')
    $(".all_months_bar_sort_field").unbind('click')
    $(".all_months_sort_field").unbind('click')

    $(document).on "click", '.agents_sort_field.sorting', () =>
      @sortColumn(0, 'asc')
    $(document).on "click", '.agents_sort_field.sorting_desc', () =>
      @sortColumn(0, 'asc')
    $(document).on "click", '.agents_sort_field.sorting_asc', () =>
      @sortColumn(0, 'desc')

    $(document).on "click", '.c0_sort_field.sorting', () =>
      @sortColumn(1, 'desc')
    $(document).on "click", '.c0_sort_field.sorting_desc', () =>
      @sortColumn(1, 'asc')
    $(document).on "click", '.c0_sort_field.sorting_asc', () =>
      @sortColumn(1, 'desc')

    $(document).on "click", '.c1_sort_field.sorting', () =>
      @sortColumn(2, 'desc')
    $(document).on "click", '.c1_sort_field.sorting_desc', () =>
      @sortColumn(2, 'asc')
    $(document).on "click", '.c1_sort_field.sorting_asc', () =>
      @sortColumn(2, 'desc')

    $(document).on "click", '.c2_sort_field.sorting', () =>
      @sortColumn(3, 'desc')
    $(document).on "click", '.c2_sort_field.sorting_desc', () =>
      @sortColumn(3, 'asc')
    $(document).on "click", '.c2_sort_field.sorting_asc', () =>
      @sortColumn(3, 'desc')

    $(document).on "click", '.c3_sort_field.sorting', () =>
      @sortColumn(4, 'desc')
    $(document).on "click", '.c3_sort_field.sorting_desc', () =>
      @sortColumn(4, 'asc')
    $(document).on "click", '.c3_sort_field.sorting_asc', () =>
      @sortColumn(4, 'desc')

    $(document).on "click", '.c4_sort_field.sorting', () =>
      @sortColumn(5, 'desc')
    $(document).on "click", '.c4_sort_field.sorting_desc', () =>
      @sortColumn(5, 'asc')
    $(document).on "click", '.c4_sort_field.sorting_asc', () =>
      @sortColumn(5, 'desc')

    $(document).on "click", '.c5_sort_field.sorting', () =>
      @sortColumn(6, 'desc')
    $(document).on "click", '.c5_sort_field.sorting_desc', () =>
      @sortColumn(6, 'asc')
    $(document).on "click", '.c5_sort_field.sorting_asc', () =>
      @sortColumn(6, 'desc')

    $(document).on "click", '.c6_sort_field.sorting', () =>
      @sortColumn(7, 'desc')
    $(document).on "click", '.c6_sort_field.sorting_desc', () =>
      @sortColumn(7, 'asc')
    $(document).on "click", '.c6_sort_field.sorting_asc', () =>
      @sortColumn(7, 'desc')

    $(document).on "click", '.c7_sort_field.sorting', () =>
      @sortColumn(8, 'desc')
    $(document).on "click", '.c7_sort_field.sorting_desc', () =>
      @sortColumn(8, 'asc')
    $(document).on "click", '.c7_sort_field.sorting_asc', () =>
      @sortColumn(8, 'desc')

    $(document).on "click", '.c8_sort_field.sorting', () =>
      @sortColumn(9, 'desc')
    $(document).on "click", '.c8_sort_field.sorting_desc', () =>
      @sortColumn(9, 'asc')
    $(document).on "click", '.c8_sort_field.sorting_asc', () =>
      @sortColumn(9, 'desc')

    $(document).on "click", '.c9_sort_field.sorting', () =>
      @sortColumn(10, 'desc')
    $(document).on "click", '.c9_sort_field.sorting_desc', () =>
      @sortColumn(10, 'asc')
    $(document).on "click", '.c9_sort_field.sorting_asc', () =>
      @sortColumn(10, 'desc')

    $(document).on "click", '.c10_sort_field.sorting', () =>
      @sortColumn(11, 'desc')
    $(document).on "click", '.c10_sort_field.sorting_desc', () =>
      @sortColumn(11, 'asc')
    $(document).on "click", '.c10_sort_field.sorting_asc', () =>
      @sortColumn(11, 'desc')

    $(document).on "click", '.c11_sort_field.sorting', () =>
      @sortColumn(12, 'desc')
    $(document).on "click", '.c11_sort_field.sorting_desc', () =>
      @sortColumn(12, 'asc')
    $(document).on "click", '.c11_sort_field.sorting_asc', () =>
      @sortColumn(12, 'desc')

    $(document).on "click", '.all_months_bar_sort_field.sorting', () =>
      @sortColumn(13, 'desc')
    $(document).on "click", '.all_months_bar_sort_field.sorting_desc', () =>
      @sortColumn(13, 'asc')
    $(document).on "click", '.all_months_bar_sort_field.sorting_asc', () =>
      @sortColumn(13, 'desc')

    $(document).on "click", '.all_months_sort_field.sorting', () =>
      @sortColumn(14, 'desc')
    $(document).on "click", '.all_months_sort_field.sorting_desc', () =>
      @sortColumn(14, 'asc')
    $(document).on "click", '.all_months_sort_field.sorting_asc', () =>
      @sortColumn(14, 'desc')
      
  sortColumn: (col, sortDirection) ->
    @dataTable.column(col).order(sortDirection).draw()
    

      
