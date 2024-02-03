class Cobalt.ConversionsForPropertiesShowController
  
  initialize: () ->
    @getParams()
    @date = @params["date"]
    @team_code = $('#team_code').children("option:selected").val()
    if @date
      @baseDataTableUrl = "/conversions_for_properties.json?date=#{@date}&team_code=#{@team_code}"
    else
      @baseDataTableUrl = "/conversions_for_properties.json?team_code=#{@team_code}"
    
    @createDataTable() 

    @setupDatePicker()

    @setupCFPGraphs()

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
        { targets: 1, sClass: "units_sort_field" },
        { targets: 2, sClass: "occupancy_sort_field" },
        { targets: 3, sClass: "trending_sort_field" },
        { targets: 4, sClass: "avg_renewal_sort_field" },
        { targets: 5, sClass: "avg_decline_sort_field" },
        { targets: 6, sClass: "avg_conversion_sort_field" },
        { targets: 7, sClass: "avg_closing_sort_field" },
        { targets: 8, sClass: "leads_needed_sort_field" },
        { targets: 9, sClass: "leads_reported_sort_field" },
        { targets: 10, sClass: "druid_leads_sort_field" },
        { targets: 11, sClass: "alert_sort_field" },
        { targets: 12, sClass: "ideal_leads_field" },
        { targets: 13, sClass: "bluestone_leads_field" }
      ]
      initComplete: () =>
        @customizeSorting()
      drawCallback: () =>
      fnServerParams: (aoData) =>
  
    @dataTable = $("#conversions_for_properties_table").DataTable(options)
    
    
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
    $(".units_sort_field").unbind('click')
    $(".occupancy_sort_field").unbind('click')
    $(".trending_sort_field").unbind('click')
    $(".avg_renewal_sort_field").unbind('click')
    $(".avg_decline_sort_field").unbind('click')
    $(".avg_conversion_sort_field").unbind('click')
    $(".avg_closing_sort_field").unbind('click')
    $(".leads_needed_sort_field").unbind('click')
    $(".leads_reported_sort_field").unbind('click')
    $(".druid_leads_sort_field").unbind('click')
    $(".alert_sort_field").unbind('click')
    $(".ideal_leads_field").unbind('click')
    $(".bluestone_leads_field").unbind('click')

    $(document).on "click", '.properties_sort_field.sorting', () =>
      @sortProperties('asc')
    $(document).on "click", '.properties_sort_field.sorting_desc', () =>
      @sortProperties('asc')
    $(document).on "click", '.properties_sort_field.sorting_asc', () =>
      @sortProperties('desc')

    $(document).on "click", '.units_sort_field.sorting', () =>
      @sortUnits('asc')
    $(document).on "click", '.units_sort_field.sorting_desc', () =>
      @sortUnits('asc')
    $(document).on "click", '.units_sort_field.sorting_asc', () =>
      @sortUnits('desc')
      
    $(document).on "click", '.occupancy_sort_field.sorting', () =>
      @sortOccupancy('asc')
    $(document).on "click", '.occupancy_sort_field.sorting_desc', () =>
      @sortOccupancy('asc')
    $(document).on "click", '.occupancy_sort_field.sorting_asc', () =>
      @sortOccupancy('desc')

    $(document).on "click", '.trending_sort_field.sorting', () =>
      @sortTrending('asc')
    $(document).on "click", '.trending_sort_field.sorting_desc', () =>
      @sortTrending('asc')
    $(document).on "click", '.trending_sort_field.sorting_asc', () =>
      @sortTrending('desc')

    $(document).on "click", '.avg_renewal_sort_field.sorting', () =>
      @sortAvgRenewal('asc')
    $(document).on "click", '.avg_renewal_sort_field.sorting_desc', () =>
      @sortAvgRenewal('asc')
    $(document).on "click", '.avg_renewal_sort_field.sorting_asc', () =>
      @sortAvgRenewal('desc')
    
    $(document).on "click", '.avg_decline_sort_field.sorting', () =>
      @sortAvgDecline('asc')
    $(document).on "click", '.avg_decline_sort_field.sorting_desc', () =>
      @sortAvgDecline('asc')
    $(document).on "click", '.avg_decline_sort_field.sorting_asc', () =>
      @sortAvgDecline('desc')

    $(document).on "click", '.avg_conversion_sort_field.sorting', () =>
      @sortAvgConversion('asc')
    $(document).on "click", '.avg_conversion_sort_field.sorting_desc', () =>
      @sortAvgConversion('asc')
    $(document).on "click", '.avg_conversion_sort_field.sorting_asc', () =>
      @sortAvgConversion('desc')

    $(document).on "click", '.avg_closing_sort_field.sorting', () =>
      @sortAvgClosing('asc')
    $(document).on "click", '.avg_closing_sort_field.sorting_desc', () =>
      @sortAvgClosing('asc')
    $(document).on "click", '.avg_closing_sort_field.sorting_asc', () =>
      @sortAvgClosing('desc')
    
    $(document).on "click", '.leads_needed_sort_field.sorting', () =>
      @sortLeadsNeeded('asc')
    $(document).on "click", '.leads_needed_sort_field.sorting_desc', () =>
      @sortLeadsNeeded('asc')
    $(document).on "click", '.leads_needed_sort_field.sorting_asc', () =>
      @sortLeadsNeeded('desc')

    $(document).on "click", '.leads_reported_sort_field.sorting', () =>
      @sortLeadsReported('asc')
    $(document).on "click", '.leads_reported_sort_field.sorting_desc', () =>
      @sortLeadsReported('asc')
    $(document).on "click", '.leads_reported_sort_field.sorting_asc', () =>
      @sortLeadsReported('desc')

    $(document).on "click", '.druid_leads_sort_field.sorting', () =>
      @sortDruidLeads('asc')
    $(document).on "click", '.druid_leads_sort_field.sorting_desc', () =>
      @sortDruidLeads('asc')
    $(document).on "click", '.druid_leads_sort_field.sorting_asc', () =>
      @sortDruidLeads('desc')

    $(document).on "click", '.alert_sort_field.sorting', () =>
      @sortAlert('asc')
    $(document).on "click", '.alert_sort_field.sorting_desc', () =>
      @sortAlert('asc')
    $(document).on "click", '.alert_sort_field.sorting_asc', () =>
      @sortAlert('desc')

    $(document).on "click", '.ideal_leads_field.sorting', () =>
      @sortIdealLeads('asc')
    $(document).on "click", '.ideal_leads_field.sorting_desc', () =>
      @sortIdealLeads('asc')
    $(document).on "click", '.ideal_leads_field.sorting_asc', () =>
      @sortIdealLeads('desc')

    $(document).on "click", '.bluestone_leads_field.sorting', () =>
      @sortBluestoneLeads('asc')
    $(document).on "click", '.bluestone_leads_field.sorting_desc', () =>
      @sortBluestoneLeads('asc')
    $(document).on "click", '.bluestone_leads_field.sorting_asc', () =>
      @sortBluestoneLeads('desc')

  sortProperties: (sortDirection) ->
    @dataTable.column(0).order(sortDirection).draw()

  sortUnits: (sortDirection) ->
    @dataTable.column(1).order(sortDirection).draw()

  sortOccupancy: (sortDirection) ->
    @dataTable.column(2).order(sortDirection).draw()

  sortTrending: (sortDirection) ->
    @dataTable.column(3).order(sortDirection).draw()

  sortAvgRenewal: (sortDirection) ->
    @dataTable.column(4).order(sortDirection).draw()

  sortAvgDecline: (sortDirection) ->
    @dataTable.column(5).order(sortDirection).draw()

  sortAvgConversion: (sortDirection) ->
    @dataTable.column(6).order(sortDirection).draw()

  sortAvgClosing: (sortDirection) ->
    @dataTable.column(7).order(sortDirection).draw()

  sortLeadsNeeded: (sortDirection) ->
    @dataTable.column(8).order(sortDirection).draw()

  sortLeadsReported: (sortDirection) ->
    @dataTable.column(9).order(sortDirection).draw()

  sortDruidLeads: (sortDirection) ->
    @dataTable.column(10).order(sortDirection).draw()

  sortAlert: (sortDirection) ->
    @dataTable.column(11).order(sortDirection).draw()

  sortIdealLeads: (sortDirection) ->
    @dataTable.column(12).order(sortDirection).draw()

  sortBluestoneLeads: (sortDirection) ->
    @dataTable.column(13).order(sortDirection).draw()

  setupCFPGraphs: () ->
    $(document).off 'click', '#conversions_for_properties tbody td span[data-metric]'
    $(document).on 'click', '#conversions_for_properties tbody td span[data-metric]', (e) =>
      $target = $(e.target)
      cfpAttribute = $target.attr("data-metric")
      cfaId = $target.parents("tr").find(".conversions_for_agents_id").val()
      teamId = $target.parents("tr").find(".team_id").val()
      date = $target.parents("tr").find(".date").val()

      if cfaId == "portfolio" && cfpAttribute == "prospects_30days"
        window.open "/conversions_for_agents_charts?portfolio=1&date=#{date}&full_size=1&custom_attributes=#{cfpAttribute}", "_self"
        return
      else if cfaId == "team" && teamId && cfpAttribute == "prospects_30days"
        window.open "/conversions_for_agents_charts?team_id=#{teamId}&date=#{date}&full_size=1&custom_attributes=#{cfpAttribute}", "_self"
        return
      else if cfaId && cfpAttribute == "prospects_30days"
        window.open "/conversions_for_agents_charts?cfa_id=#{cfaId}&date=#{date}&full_size=1&custom_attributes=#{cfpAttribute}", "_self"
        return

  setupDatePicker: () ->
    $("#datepicker").datepicker 
      onSelect: (dateText) =>
        encodedDate = encodeURI(dateText)
        @dataTable.ajax.url("/conversions_for_properties.json?date=#{encodedDate}&team_code=#{@team_code}").load()
