class Cobalt.BluebotRollupReportShowController
  
  initialize: () ->
    team_code = $('#team_code').children("option:selected").val()
    end_month = $('#bluebot_rollup_report_form_end_month').children("option:selected").val()
    @baseDataTableUrl = "/bluebot_rollup_report.json?team_code=#{team_code}&bluebot_rollup_report_form[end_month]=#{end_month}"
    console.log @baseDataTableUrl
    # @baseDataTableUrl = "/bluebot_rollup_report.json?bluebot_rollup_report_form[end_month]=#{end_month}"
    
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
        { targets: 0, sClass: "properties_sort_field" },
        { targets: 1, sClass: "m0_sort_field" },
        { targets: 2, sClass: "m1_sort_field" },
        { targets: 3, sClass: "m2_sort_field" },
        { targets: 4, sClass: "m3_sort_field" },
        { targets: 5, sClass: "m4_sort_field" },
        { targets: 6, sClass: "m5_sort_field" },
        { targets: 7, sClass: "m6_sort_field" },
        { targets: 8, sClass: "m7_sort_field" },
        { targets: 9, sClass: "m8_sort_field" },
        { targets: 10, sClass: "m9_sort_field" },
        { targets: 11, sClass: "m10_sort_field" },
        { targets: 12, sClass: "m11_sort_field" },
        { targets: 13, sClass: "mc_sort_field" },
        { targets: 14, sClass: "all_months_bar_sort_field" },
        { targets: 15, sClass: "all_months_sort_field" }
      ]
      initComplete: () =>
        @customizeSorting()
      drawCallback: () =>
      fnServerParams: (aoData) =>
  
    @dataTable = $("#bluebot_rollup_report_table").DataTable(options)
    
    
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
    $(".m0_sort_field").unbind('click')
    $(".m1_sort_field").unbind('click')
    $(".m2_sort_field").unbind('click')
    $(".m3_sort_field").unbind('click')
    $(".m4_sort_field").unbind('click')
    $(".m5_sort_field").unbind('click')
    $(".m6_sort_field").unbind('click')
    $(".m7_sort_field").unbind('click')
    $(".m8_sort_field").unbind('click')
    $(".m9_sort_field").unbind('click')
    $(".m10_sort_field").unbind('click')
    $(".m11_sort_field").unbind('click')
    $(".mc_sort_field").unbind('click')
    $(".all_months_bar_sort_field").unbind('click')
    $(".all_months_sort_field").unbind('click')

    $(document).on "click", '.properties_sort_field.sorting', () =>
      @sortColumn(0, 'asc')
    $(document).on "click", '.properties_sort_field.sorting_desc', () =>
      @sortColumn(0, 'asc')
    $(document).on "click", '.properties_sort_field.sorting_asc', () =>
      @sortColumn(0, 'desc')

    $(document).on "click", '.m0_sort_field.sorting', () =>
      @sortColumn(1, 'desc')
    $(document).on "click", '.m0_sort_field.sorting_desc', () =>
      @sortColumn(1, 'asc')
    $(document).on "click", '.m0_sort_field.sorting_asc', () =>
      @sortColumn(1, 'desc')

    $(document).on "click", '.m1_sort_field.sorting', () =>
      @sortColumn(2, 'desc')
    $(document).on "click", '.m1_sort_field.sorting_desc', () =>
      @sortColumn(2, 'asc')
    $(document).on "click", '.m1_sort_field.sorting_asc', () =>
      @sortColumn(2, 'desc')

    $(document).on "click", '.m2_sort_field.sorting', () =>
      @sortColumn(3, 'desc')
    $(document).on "click", '.m2_sort_field.sorting_desc', () =>
      @sortColumn(3, 'asc')
    $(document).on "click", '.m2_sort_field.sorting_asc', () =>
      @sortColumn(3, 'desc')

    $(document).on "click", '.m3_sort_field.sorting', () =>
      @sortColumn(4, 'desc')
    $(document).on "click", '.m3_sort_field.sorting_desc', () =>
      @sortColumn(4, 'asc')
    $(document).on "click", '.m3_sort_field.sorting_asc', () =>
      @sortColumn(4, 'desc')

    $(document).on "click", '.m4_sort_field.sorting', () =>
      @sortColumn(5, 'desc')
    $(document).on "click", '.m4_sort_field.sorting_desc', () =>
      @sortColumn(5, 'asc')
    $(document).on "click", '.m4_sort_field.sorting_asc', () =>
      @sortColumn(5, 'desc')

    $(document).on "click", '.m5_sort_field.sorting', () =>
      @sortColumn(6, 'desc')
    $(document).on "click", '.m5_sort_field.sorting_desc', () =>
      @sortColumn(6, 'asc')
    $(document).on "click", '.m5_sort_field.sorting_asc', () =>
      @sortColumn(6, 'desc')

    $(document).on "click", '.m6_sort_field.sorting', () =>
      @sortColumn(7, 'desc')
    $(document).on "click", '.m6_sort_field.sorting_desc', () =>
      @sortColumn(7, 'asc')
    $(document).on "click", '.m6_sort_field.sorting_asc', () =>
      @sortColumn(7, 'desc')

    $(document).on "click", '.m7_sort_field.sorting', () =>
      @sortColumn(8, 'desc')
    $(document).on "click", '.m7_sort_field.sorting_desc', () =>
      @sortColumn(8, 'asc')
    $(document).on "click", '.m7_sort_field.sorting_asc', () =>
      @sortColumn(8, 'desc')

    $(document).on "click", '.m8_sort_field.sorting', () =>
      @sortColumn(9, 'desc')
    $(document).on "click", '.m8_sort_field.sorting_desc', () =>
      @sortColumn(9, 'asc')
    $(document).on "click", '.m8_sort_field.sorting_asc', () =>
      @sortColumn(9, 'desc')

    $(document).on "click", '.m9_sort_field.sorting', () =>
      @sortColumn(10, 'desc')
    $(document).on "click", '.m9_sort_field.sorting_desc', () =>
      @sortColumn(10, 'asc')
    $(document).on "click", '.m9_sort_field.sorting_asc', () =>
      @sortColumn(10, 'desc')

    $(document).on "click", '.m10_sort_field.sorting', () =>
      @sortColumn(11, 'desc')
    $(document).on "click", '.m10_sort_field.sorting_desc', () =>
      @sortColumn(11, 'asc')
    $(document).on "click", '.m10_sort_field.sorting_asc', () =>
      @sortColumn(11, 'desc')

    $(document).on "click", '.m11_sort_field.sorting', () =>
      @sortColumn(12, 'desc')
    $(document).on "click", '.m11_sort_field.sorting_desc', () =>
      @sortColumn(12, 'asc')
    $(document).on "click", '.m11_sort_field.sorting_asc', () =>
      @sortColumn(12, 'desc')

    $(document).on "click", '.mc_sort_field.sorting', () =>
      @sortColumn(13, 'desc')
    $(document).on "click", '.mc_sort_field.sorting_desc', () =>
      @sortColumn(13, 'asc')
    $(document).on "click", '.mc_sort_field.sorting_asc', () =>
      @sortColumn(13, 'desc')

    $(document).on "click", '.all_months_bar_sort_field.sorting', () =>
      @sortColumn(14, 'desc')
    $(document).on "click", '.all_months_bar_sort_field.sorting_desc', () =>
      @sortColumn(14, 'asc')
    $(document).on "click", '.all_months_bar_sort_field.sorting_asc', () =>
      @sortColumn(14, 'desc')

    $(document).on "click", '.all_months_sort_field.sorting', () =>
      @sortColumn(15, 'desc')
    $(document).on "click", '.all_months_sort_field.sorting_desc', () =>
      @sortColumn(15, 'asc')
    $(document).on "click", '.all_months_sort_field.sorting_asc', () =>
      @sortColumn(15, 'desc')
      
  sortColumn: (col, sortDirection) ->
    @dataTable.column(col).order(sortDirection).draw()
    

      
