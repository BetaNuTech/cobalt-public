class Cobalt.MetricsIndexController
  
  initialize: () ->
    @maint_user = $("#maint_user").val()
    @manager_view = $("#manager_view").val()
    if @manager_view == true
      @maint_user = false

    @getParams()
    @team_code = @params["team_code"]
    if @team_code
      if @manager_view == true
        @baseDataTableUrl = "/metrics.json?team_code=#{@team_code}&manager_view=true"
      else
        @baseDataTableUrl = "/metrics.json?team_code=#{@team_code}"
    else
      if @manager_view == true
        @baseDataTableUrl = "/metrics.json?manager_view=true"
      else
        @baseDataTableUrl = "/metrics.json"
    
    @chartControl0 = new Cobalt.ChartControl()
    @chartControl1 = new Cobalt.ChartControl()
    @chartControl2 = new Cobalt.ChartControl()
    @chartControl3 = new Cobalt.ChartControl()
    @chartControl4 = new Cobalt.ChartControl()
    
    if @maint_user == true
      console.log "Displaying Maint Table"
      @createMaintDataTable()
    else
      console.log "Displaying Manager Table"
      @createDataTable()

    @setupDatePicker()
    @setupMetricGraphs()  
    @setupMetricDrillDowns()
    @setupComplianceIssues()
    $("table .info").tooltip()
    @setupBlinkText()
    @collectionSortCycle = 0
    @basisSortCycle = 0
    @propertySortCycle = 0

    @hideHUD()
    # @setupHUD()
      
      
  createDataTable: () ->
    options = 
      ajax: 
        url: @baseDataTableUrl
        type: 'post'
      ordering: true
      processing: true
      serverSide: true
      paging: false
      info: false
      searching: false
      order: [[ 6, "desc" ]]
      scrollY: "#{@getAvailableContentHeight()}px"
      scrollX: "true"
      scrollCollapse: true
      fixedColumns:
        leftColumns: 1
      columnDefs: [
        { orderable: false, targets: -1 },
        { targets: 0, sClass: "properties_sort_field" },
        { targets: 1, sClass: "basis_sort_field" },
        { targets: 8, sClass: "collections_sort_field" }
        # { orderable: false, targets: [1,2,3,4,5,7,8,10,11,12] }
      ]
      initComplete: () =>
        @customizeSorting()
      drawCallback: () =>
        @setupRowToFlash()  
      fnServerParams: (aoData) =>
        aoData['property_sort_cycle'] = @propertySortCycle % 4
        aoData['basis_sort_cycle'] = @basisSortCycle % 4
        aoData['collection_sort_cycle'] = @collectionSortCycle % 4

  
    @dataTable = $("#metrics_table").DataTable(options)
    
    
    $(window).resize () =>
      height = @getAvailableContentHeight()
      $(".dataTables_scrollBody").css("max-height", "#{height}px")
    

  createMaintDataTable: () ->
    options = 
      ajax: 
        url: @baseDataTableUrl
        type: 'post'
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
        { orderable: false, targets: 0 }
      ]
      initComplete: () =>
        @customizeMaintSorting()
      drawCallback: () =>
        @setupRowToFlash()  
      fnServerParams: (aoData) =>
        aoData['property_sort_cycle'] = @propertySortCycle % 2
  
    @dataTable = $("#metrics_table").DataTable(options)
    
    $(window).resize () =>
      height = @getAvailableContentHeight()
      $(".dataTables_scrollBody").css("max-height", "#{height}px")
    
  
  getAvailableContentHeight: () ->
    tableHeaderHeight = 57
    heightAdjustment = 18
    
    height = $(window).outerHeight() - $("#header").height() - tableHeaderHeight - heightAdjustment
    return height
    
  setupDatePicker: () ->
    $("#datepicker").datepicker 
      onSelect: (dateText) =>
        encodedDate = encodeURI(dateText);
        $('#property_charts_date').val(encodedDate);
        $('#metric_attribute_charts_date').val(encodedDate);
        if @team_code
          @dataTable.ajax.url("/metrics.json?date=#{encodedDate}&team_code=#{@team_code}").load()
        else
          @dataTable.ajax.url("/metrics.json?date=#{encodedDate}").load()      
        
  setupRowToFlash: () ->
    $(".flash_row_blue").each () ->
      $(this).parents("td").addClass("flash_background flash_blue")
    $(".flash_row_red").each () ->
      $(this).parents("td").addClass("flash_background flash_red")
        
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

  
  customizeSorting: () ->
    $(".properties_sort_field").unbind('click')
    $(".basis_sort_field").unbind('click')
    $(".collections_sort_field").unbind('click')

    $(document).on "click", '.properties_sort_field.sorting', () =>
      @propertySortCycle = 0
      @sortProperties('asc')

    $(document).on "click", '.properties_sort_field.sorting_desc', () =>
      @sortProperties('asc')

    $(document).on "click", '.properties_sort_field.sorting_asc', () =>
      @sortProperties('desc')
      
    $(document).on "click", '.basis_sort_field.sorting', () =>
      @basisSortCycle = 0
      @sortBasis('asc')
    
    $(document).on "click", '.basis_sort_field.sorting_desc', () =>
      @sortBasis('asc')

    $(document).on "click", '.basis_sort_field.sorting_asc', () =>
      @sortBasis('desc')

    $(document).on "click", '.collections_sort_field.sorting', () =>
      @collectionSortCycle = 0
      @sortCollections('asc')
    
    $(document).on "click", '.collections_sort_field.sorting_desc', () =>
      @sortCollections('asc')

    $(document).on "click", '.collections_sort_field.sorting_asc', () =>
      @sortCollections('desc')

  customizeMaintSorting: () ->
    $(".properties_sort_field").unbind('click')
    
    $(document).on "click", '.properties_sort_field.sorting_desc', () =>
      @sortProperties('asc')

    $(document).on "click", '.properties_sort_field.sorting_asc', () =>
      @sortProperties('desc')

  sortProperties: (sortDirection) ->
    @propertySortCycle += 1
    @dataTable.column(0).order(sortDirection).draw()

  sortBasis: (sortDirection) ->
    @dataTable.column(1).order(sortDirection).draw()
    @basisSortCycle += 1

  sortCollections: (sortDirection) ->
    @dataTable.column(8).order(sortDirection).draw()
    @collectionSortCycle += 1
    
  setupMetricGraphs: () ->
    $('body').off 'click'
    $('body').on 'click', (e) =>
      if $(e.target).closest('.metric_graph_container').length > 0
        $('#metrics .metric_graph_container').remove()        
        return 
      else
        $('#metrics .metric_graph_container').remove()         

    $(document).off 'click', '#metrics tbody td span[data-metric]'
    $(document).on 'click', '#metrics tbody td span[data-metric]', (e) =>
      $target = $(e.target)
      metricAttribute = $target.attr("data-metric")
      metricId = $target.parents("tr").find(".metric_id").val()
      propertyName = $target.parents("tr").find(".property_name").text()

      if metricAttribute == 'trending_all_graphs'
        window.open "/property_charts?code=#{propertyName}&metricId=#{metricId}&full_size=1&custom_attributes=#{metricAttribute}", "_self"
        return
      else if metricAttribute == 'occupancy_all_graphs'
        window.open "/property_charts?code=#{propertyName}&metricId=#{metricId}&full_size=1&custom_attributes=#{metricAttribute}", "_self"
        return
      else if metricAttribute == 'average_rents_all_graphs'
        window.open "/property_charts?code=#{propertyName}&metricId=#{metricId}&full_size=1&custom_attributes=#{metricAttribute}", "_self"
        return
      else if metricAttribute == 'basis_all_graphs'
        window.open "/property_charts?code=#{propertyName}&metricId=#{metricId}&full_size=1&custom_attributes=#{metricAttribute}", "_self"
        return
      else if metricAttribute == 'expenses_all_graphs'
        window.open "/property_charts?code=#{propertyName}&metricId=#{metricId}&full_size=1&custom_attributes=#{metricAttribute}", "_self"
        return
      else if metricAttribute == 'renewals_all_graphs'
        window.open "/property_charts?code=#{propertyName}&metricId=#{metricId}&full_size=1&custom_attributes=#{metricAttribute}", "_self"
        return
      else if metricAttribute == 'collections_all_graphs'
        window.open "/property_charts?code=#{propertyName}&metricId=#{metricId}&full_size=1&custom_attributes=#{metricAttribute}", "_self"
        return
      else if metricAttribute == 'maintenance_all_graphs'
        window.open "/property_charts?code=#{propertyName}&metricId=#{metricId}&full_size=1&custom_attributes=#{metricAttribute}", "_self"
        return
      else
        $graphContainer = $("<div class='metric_graph_container'></div>")
        width = $(window).outerWidth() - ($(window).outerWidth() / 10)
        height = $(window).outerHeight() / 2
        $graphContainer.width(width)
        $graphContainer.height(height)
        
        # Old code to show graph below metric clicked
        # if $target.parents("td").find(".property_name").length > 0
        #   $graphContainer.css("position", "fixed")
        # else
        #   $graphContainer.css("position", "absolute")
          
        $graphContainer.css("position", "fixed")
        $graphContainer.css("top", (2 * $(window).outerHeight() / 3) - (height/2))
        $graphContainer.css("left", ($(window).outerWidth() / 2) - (width/2))
        $('#metrics').append($graphContainer)
      
        title = "#{propertyName}: #{metricAttribute}"
        
        @chartControl0.create("/metrics/#{metricId}/metric_charts.json?metric_attribute=#{metricAttribute}",
          ".metric_graph_container", title, width, height)

  setupMetricDrillDowns: () ->
    $(document).on 'click', '#metrics tbody td span[data-rent-change-reasons]'
    $(document).on 'click', '#metrics tbody td span[data-rent-change-reasons]', (e) =>
      $target = $(e.target)
      metricId = $target.parents("tr").find(".metric_id").val()
      window.open "/rent_change_reasons?metric_id=#{metricId}", "_self"

    $(document).off 'click', '#metrics tbody td span[data-incomplete-work-orders]'
    $(document).on 'click', '#metrics tbody td span[data-incomplete-work-orders]', (e) =>
      $target = $(e.target)
      propertyId = $target.parents("tr").find(".property_id").val()
      date = $target.parents("tr").find(".date").val()
      window.open "/incomplete_work_orders?property_id=#{propertyId}&date=#{date}", "_self"

    $(document).off 'click', '#metrics tbody td span[data-renewals-unknown]'
    $(document).on 'click', '#metrics tbody td span[data-renewals-unknown]', (e) =>
      $target = $(e.target)
      propertyId = $target.parents("tr").find(".property_id").val()
      date = $target.parents("tr").find(".date").val()
      window.open "/renewals_unknown_details?property_id=#{propertyId}&date=#{date}", "_self"

    $(document).off 'click', '#metrics tbody td span[data-collections-non-eviction-past20]'
    $(document).on 'click', '#metrics tbody td span[data-collections-non-eviction-past20]', (e) =>
      $target = $(e.target)
      propertyId = $target.parents("tr").find(".property_id").val()
      date = $target.parents("tr").find(".date").val()
      window.open "/collections_non_eviction_past20_details?property_id=#{propertyId}&date=#{date}", "_self"

  setupComplianceIssues: () ->
    $(document).off 'click', 'span.metrics_compliance_issue'
    $(document).on 'click', 'span.metrics_compliance_issue', (e) =>
      $target = $(e.target)
      propertyId = $target.parents("tr").find(".property_id").val()
      date = $target.parents("tr").find(".date").val()
      window.open "/compliance_issues?property_id=#{propertyId}&date=#{date}", "_self"
      
  setupHUD: () ->
    $(document).off 'click', '#metrics .property_name a'
    $(document).on 'click', '#metrics .property_name a', (e) =>
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