class Cobalt.CollectionsDetailsShowController
  
  initialize: () ->
    @getParams()
    @team_code = $('#team_code').children("option:selected").val()
    @record_id = @params["id"]
    date = @params["date"]
    if @record_id
      if date
        @baseDataTableUrl = "/collections_details.json?id=#{@record_id}&team_code=#{@team_code}&date=#{date}"
      else
        @baseDataTableUrl = "/collections_details.json?id=#{@record_id}&team_code=#{@team_code}"
    else
      if date
        @baseDataTableUrl = "/collections_details.json?team_code=#{@team_code}&date=#{date}"
      else
        @baseDataTableUrl = "/collections_details.json?team_code=#{@team_code}"

    @chartControl = new Cobalt.ChartControl()
    @setupGraphs

    @createDataTable() 

    @setupDatePicker()

    @updateTimestamp()

    @setupCollectionsByTenantDetails()

    @chartControl = new Cobalt.ChartControl()
    @setupGraphs()

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
        { targets: 0, sClass: "properties_sort_field" },
        { targets: 1, sClass: "units_occupancy_sort_field" },
        { targets: 2, sClass: "total_paid_sort_field" },
        { targets: 3, sClass: "num_of_unknown_sort_field" },
        { targets: 4, sClass: "num_of_payment_plan_sort_field" },
        { targets: 5, sClass: "num_of_paid_in_full_sort_field" },
        { targets: 6, sClass: "num_of_evictions_sort_field" }
      ]
      initComplete: () =>
        @customizeSorting()
      drawCallback: () =>
      fnServerParams: (aoData) =>
  
    @dataTable = $("#collections_details_table").DataTable(options)
    
    
    $(window).resize () =>
      height = @getAvailableContentHeight()
      $(".dataTables_scrollBody").css("max-height", "#{height}px")
    
  
  updateTimestamp: () ->
    utcTimestamp = $('#timestamp_string').val()
    d = new Date(utcTimestamp)
    $('#timestamp_localized').html(d.toString())

  setupDatePicker: () ->
    $("#datepicker").datepicker 
      onSelect: (dateText) =>
        encodedDate = encodeURI(dateText);
        if @record_id
            window.location.assign "/collections_details?id=#{@record_id}&team_code=#{@team_code}&date=#{encodedDate}"
        else
            window.location.assign "/collections_details?team_code=#{@team_code}&date=#{encodedDate}"

  setupCollectionsByTenantDetails: () ->
    $(document).off 'click', 'span[collections_by_tenant_details]'
    $(document).on 'click', 'span[collections_by_tenant_details]', (e) =>
      $target = $(e.target)
      property_id = $target.parents("tr").find(".property_id").val()
      latest_collectiions_by_tenant_detail_id = $target.parents("tr").find(".latest_collectiions_by_tenant_detail_id").val()
      window.open "/collections_by_tenant_details?property_id=#{property_id}&latest_collectiions_by_tenant_detail_id=#{latest_collectiions_by_tenant_detail_id}", "_self"

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
    $(".units_occupancy_sort_field").unbind('click')
    $(".total_paid_sort_field").unbind('click')
    $(".num_of_unknown_sort_field").unbind('click')
    $(".num_of_payment_plan_sort_field").unbind('click')
    $(".num_of_paid_in_full_sort_field").unbind('click')
    $(".num_of_evictions_sort_field").unbind('click')

    $(document).on "click", '.properties_sort_field.sorting', () =>
      @sortProperties('asc')
    $(document).on "click", '.properties_sort_field.sorting_desc', () =>
      @sortProperties('asc')
    $(document).on "click", '.properties_sort_field.sorting_asc', () =>
      @sortProperties('desc')

    $(document).on "click", '.units_occupancy_sort_field.sorting', () =>
      @sortUnitsOccupancy('asc')
    $(document).on "click", '.units_occupancy_sort_field.sorting_desc', () =>
      @sortUnitsOccupancy('asc')
    $(document).on "click", '.units_occupancy_sort_field.sorting_asc', () =>
      @sortUnitsOccupancy('desc')
      
    $(document).on "click", '.total_paid_sort_field.sorting', () =>
      @sortTotalPaid('asc')
    $(document).on "click", '.total_paid_sort_field.sorting_desc', () =>
      @sortTotalPaid('asc')
    $(document).on "click", '.total_paid_sort_field.sorting_asc', () =>
      @sortTotalPaid('desc')

    $(document).on "click", '.num_of_unknown_sort_field.sorting', () =>
      @sortNumUnknown('asc')
    $(document).on "click", '.num_of_unknown_sort_field.sorting_desc', () =>
      @sortNumUnknown('asc')
    $(document).on "click", '.num_of_unknown_sort_field.sorting_asc', () =>
      @sortNumUnknown('desc')
    
    $(document).on "click", '.num_of_payment_plan_sort_field.sorting', () =>
      @sortNumPaymentPlan('asc')
    $(document).on "click", '.num_of_payment_plan_sort_field.sorting_desc', () =>
      @sortNumPaymentPlan('asc')
    $(document).on "click", '.num_of_payment_plan_sort_field.sorting_asc', () =>
      @sortNumPaymentPlan('desc')

    $(document).on "click", '.num_of_paid_in_full_sort_field.sorting', () =>
      @sortNumPaidInFull('asc')
    $(document).on "click", '.num_of_paid_in_full_sort_field.sorting_desc', () =>
      @sortNumPaidInFull('asc')
    $(document).on "click", '.num_of_paid_in_full_sort_field.sorting_asc', () =>
      @sortNumPaidInFull('desc')

    $(document).on "click", '.num_of_evictions_sort_field.sorting', () =>
      @sortNumEvictions('asc')
    $(document).on "click", '.num_of_evictions_sort_field.sorting_desc', () =>
      @sortNumEvictions('asc')
    $(document).on "click", '.num_of_evictions_sort_field.sorting_asc', () =>
      @sortNumEvictions('desc')

  sortProperties: (sortDirection) ->
    @dataTable.column(0).order(sortDirection).draw()

  sortUnitsOccupancy: (sortDirection) ->
    @dataTable.column(1).order(sortDirection).draw()

  sortTotalPaid: (sortDirection) ->
    @dataTable.column(2).order(sortDirection).draw()

  sortNumUnknown: (sortDirection) ->
    @dataTable.column(3).order(sortDirection).draw()

  sortNumPaymentPlan: (sortDirection) ->
    @dataTable.column(4).order(sortDirection).draw()

  sortNumPaidInFull: (sortDirection) ->
    @dataTable.column(5).order(sortDirection).draw()

  sortNumEvictions: (sortDirection) ->
    @dataTable.column(6).order(sortDirection).draw()

  setupGraphs: () ->
    $('body').off 'click'
    $('body').on 'click', (e) =>
      if $(e.target).closest('.graph_container').length > 0
        $('#collections_details .graph_container').remove()        
        return 
      else
        $('#collections_details .graph_container').remove()         

    $(document).off 'click', '#collections_details tbody td span[graph-attribute]'
    $(document).on 'click', '#collections_details tbody td span[graph-attribute]', (e) =>
      $target = $(e.target)
      attribute = $target.attr("graph-attribute")
      detailId = $target.parents("tr").find(".collections_detail_id").val()
      propertyName = $target.parents("tr").find(".property_name").val()

      $graphContainer = $("<div class='graph_container'></div>")
      width = $(window).outerWidth() - ($(window).outerWidth() / 10)
      height = $(window).outerHeight() / 2
      $graphContainer.width(width)
      $graphContainer.height(height)
      
      $graphContainer.css("position", "fixed")
      $graphContainer.css("top", (2 * $(window).outerHeight() / 3) - (height/2))
      $graphContainer.css("left", ($(window).outerWidth() / 2) - (width/2))
      $('#collections_details').append($graphContainer)
    
      title = "#{propertyName}: #{attribute}"
      
      @chartControl.create("/collections_details/#{detailId}/collections_detail_charts.json?attribute=#{attribute}",
        ".graph_container", title, width, height)