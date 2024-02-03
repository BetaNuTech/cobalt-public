class Cobalt.CollectionsByTenantDetailsShowController
  
  initialize: () ->
    property_id = $('#property_id').val()
    @baseDataTableUrl = "/collections_by_tenant_details.json?property_id=#{property_id}"

    @createDataTable() 

    @updateTimestamp()

    @setupBlinkText()

    @residentSortCycle = 0

    $("table .info").tooltip()
      
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
        { targets: 0, sClass: "resident_sort_field" },
        { targets: 1, sClass: "phone_email_sort_field" },
        { targets: 2, sClass: "tcode_sort_field" },
        { targets: 3, sClass: "unit_sort_field" },
        { targets: 4, sClass: "rent_sort_field" },
        { targets: 5, sClass: "unpaid_sort_field" },
        { targets: 6, sClass: "payment_plan_sort_field" },
        { targets: 7, sClass: "notice_sort_field" },
        { targets: 8, sClass: "eviction_sort_field" },
        { targets: 9, sClass: "notes_sort_field" }
      ]
      initComplete: () =>
        @customizeSorting()
      drawCallback: () =>
        @setupDarkerRows()
      fnServerParams: (aoData) =>
        aoData['resident_sort_cycle'] = @residentSortCycle % 4
  
    @dataTable = $("#collections_by_tenant_details_table").DataTable(options)
    
    
    $(window).resize () =>
      height = @getAvailableContentHeight()
      $(".dataTables_scrollBody").css("max-height", "#{height}px")
    
  setupBlinkText: () ->  
    interval_id = 1 
    while interval_id < 100
      window.clearInterval(interval_id)
      interval_id += 1

    @timer = window.setInterval(() =>
      $flashing = $('.flash.flashing')
      $notFlashing = $(".flash:not('.flashing')")
      $flashing.removeClass("flashing")
      $notFlashing.addClass("flashing")
      $flashing_background = $('.flash_background.flashing_background')
      $notFlashing_background = $(".flash_background:not('.flashing_background')")
      $flashing_background.removeClass("flashing_background")
      $notFlashing_background.addClass("flashing_background")
    , 250)

    $(document).off 'page:before-unload'
    $(document).on 'page:before-unload', (e) =>
      window.clearInterval(@timer)

  setupDarkerRows: () ->
    $(".darker_row").each () ->
      $(this).parents("tr").addClass("darker")

  
  updateTimestamp: () ->
    utcTimestamp = $('#timestamp_string').val()
    d = new Date(utcTimestamp)
    $('#timestamp_localized').html(d.toString())


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
    $(".resident_sort_field").unbind('click')
    $(".phone_email_sort_field").unbind('click')
    $(".tcode_sort_field").unbind('click')
    $(".unit_sort_field").unbind('click')
    $(".rent_sort_field").unbind('click')
    $(".unpaid_sort_field").unbind('click')
    $(".payment_plan_sort_field").unbind('click')
    $(".notice_sort_field").unbind('click')
    $(".eviction_sort_field").unbind('click')
    $(".notes_sort_field").unbind('click')

    $(document).on "click", '.resident_sort_field.sorting', () =>
      @sortResidents('asc')
    $(document).on "click", '.resident_sort_field.sorting_desc', () =>
      @sortResidents('asc')
    $(document).on "click", '.resident_sort_field.sorting_asc', () =>
      @sortResidents('desc')

    $(document).on "click", '.phone_email_sort_field.sorting', () =>
      @sortColumn(1,'asc')
    $(document).on "click", '.phone_email_sort_field.sorting_desc', () =>
      @sortColumn(1,'asc')
    $(document).on "click", '.phone_email_sort_field.sorting_asc', () =>
      @sortColumn(1,'desc')
      
    $(document).on "click", '.tcode_sort_field.sorting', () =>
      @sortColumn(2,'asc')
    $(document).on "click", '.tcode_sort_field.sorting_desc', () =>
      @sortColumn(2,'asc')
    $(document).on "click", '.tcode_sort_field.sorting_asc', () =>
      @sortColumn(2,'desc')

    $(document).on "click", '.unit_sort_field.sorting', () =>
      @sortColumn(3,'asc')
    $(document).on "click", '.unit_sort_field.sorting_desc', () =>
      @sortColumn(3,'asc')
    $(document).on "click", '.unit_sort_field.sorting_asc', () =>
      @sortColumn(3,'desc')
    
    $(document).on "click", '.rent_sort_field.sorting', () =>
      @sortColumn(4,'asc')
    $(document).on "click", '.rent_sort_field.sorting_desc', () =>
      @sortColumn(4,'asc')
    $(document).on "click", '.rent_sort_field.sorting_asc', () =>
      @sortColumn(4,'desc')

    $(document).on "click", '.unpaid_sort_field.sorting', () =>
      @sortColumn(5,'asc')
    $(document).on "click", '.unpaid_sort_field.sorting_desc', () =>
      @sortColumn(5,'asc')
    $(document).on "click", '.unpaid_sort_field.sorting_asc', () =>
      @sortColumn(5,'desc')

    $(document).on "click", '.payment_plan_sort_field.sorting', () =>
      @sortColumn(6,'asc')
    $(document).on "click", '.payment_plan_sort_field.sorting_desc', () =>
      @sortColumn(6,'asc')
    $(document).on "click", '.payment_plan_sort_field.sorting_asc', () =>
      @sortColumn(6,'desc')

    $(document).on "click", '.notice_sort_field.sorting', () =>
      @sortColumn(7,'asc')
    $(document).on "click", '.notice_sort_field.sorting_desc', () =>
      @sortColumn(7,'asc')
    $(document).on "click", '.notice_sort_field.sorting_asc', () =>
      @sortColumn(7,'desc')

    $(document).on "click", '.eviction_sort_field.sorting', () =>
      @sortColumn(8,'asc')
    $(document).on "click", '.eviction_sort_field.sorting_desc', () =>
      @sortColumn(8,'asc')
    $(document).on "click", '.eviction_sort_field.sorting_asc', () =>
      @sortColumn(8,'desc')

    $(document).on "click", '.notes_sort_field.sorting', () =>
      @sortColumn(9,'asc')
    $(document).on "click", '.notes_sort_field.sorting_desc', () =>
      @sortColumn(9,'asc')
    $(document).on "click", '.notes_sort_field.sorting_asc', () =>
      @sortColumn(9,'desc')

  sortColumn: (col, sortDirection) ->
    @dataTable.column(col).order(sortDirection).draw()
    
  sortResidents: (sortDirection) ->
    @residentSortCycle += 1
    @dataTable.column(0).order(sortDirection).draw()
      