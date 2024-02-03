class Cobalt.BlueShiftsNewController
  
  initialize: () ->
    if $("#price_image_uploads .uploaded_image").length > 0
      @priceImageUploadIndex = $(".uploaded_image").length - 1
    else
      @priceImageUploadIndex = -1
      
    $("input[type=radio], input[type=checkbox]").each (index, element) =>
      @setBlueShiftSectionVisiblity(element)
      
    $("input[type=radio], input[type=checkbox]").change (event) =>
      target = event.target
      @setBlueShiftSectionVisiblity(target)
      @setBlueShiftSubSectionVisiblity(target)
      @setProductProblemAlert(target)
      
    $(".date").datepicker(minDate: 0)
    
    if $('#image_upload_template').length > 0
      @addImageUploadField("Upload an image")

    # @setupMetricDrillDowns()
    # From _form.html.erb <span class="level-1" data-rent-change-reasons='show'><input class='metric_id' type='hidden' value='<%= @current_metric.id %>'><u>RENT CHANGE REASONS REPORT</u></span>.

    current_metric_id = $('#current_metric_id').val()
    property_id = $('#property_id').val()
    current_metric_id = $('#current_metric_id').val()
    date =  $("#created_on_date").val()
    date_for_cfp =  $("#created_on_date_for_cfp").val()
    @baseRCRDataTableUrl = "/rent_change_reasons.json?metric_id=#{current_metric_id}"
    @baseCFADataTableUrl = "/conversions_for_agents.json?property_id=#{property_id}&date=#{date}"
    @baseConversionsForPropertyDataTableUrl = "/conversions_for_properties.json?property_id=#{property_id}&date=#{date_for_cfp}"
    @baseAgentSalesRollupDataTableUrl = "/bluebot_agent_sales_rollup_report.json?property_id=#{property_id}&bluebot_rollup_report_form[end_month]=#{date}&reversed=1"
    
    @createRCRDataTable() 
    @createCFADataTable() 
    @createAgentSalesRollupDataTable() 
    @setupUnitTypeRentHistory() 
    @createConversionsForPropertiesDataTable()   
      
    return
        
  configureImageUploadField: ($element) ->   
    id = $element.attr('id')
    $this = -> $("##{id}")
    $progress = $element.siblings('.progress').hide()
    $meter = $progress.find('.meter')
    $element.S3FileField
      dataType: 'xml'
      add: (e, data) ->
        $progress.show()
        data.submit()
      done: (e, data) =>
        $imageUploadField = $(e.target)
        $progress.remove()
        $imageUploadField.attr(type: 'hidden', value: data.result.filepath, readonly: true)
        $imageUploadField.after("Caption <input type='text' class='image_caption' maxlength='255' id='blue_shift_pricing_problem_image_caption_#{@priceImageUploadIndex}' name='blue_shift[pricing_problem_image_caption_#{@priceImageUploadIndex}]'>")
        $imageUploadField.after("<img src='#{data.result.url}'><br />")
        
        $("#price_image_uploads .upload_label").remove()
        
        @addImageUploadField("Upload another image")
        
      fail: (e, data) ->
        alert("Error uploading image: #{data.errorThrown} - #{data.failReason}")
      progress: (e, data) ->
        progress = parseInt(data.loaded / data.total * 100, 10)
        $meter.css(width: "#{progress}%")    
   
  addImageUploadField: (label) ->    
    @priceImageUploadIndex += 1  
    $imageUpload = $("#image_upload_template .image_upload").clone()
    $imageUpload.find(".upload_label").text(label)
    $("#price_image_uploads").append($imageUpload)
    
    $imageUploadField = $imageUpload.find(".js-s3_file_field")
    $imageUploadField.attr("id", $imageUploadField.attr("id").replace("index", @priceImageUploadIndex))
    $imageUploadField.attr("name", $imageUploadField.attr("name").replace("index", @priceImageUploadIndex))
    @configureImageUploadField($imageUploadField)
        
  setBlueShiftSectionVisiblity: (control) ->
    if control.checked and control.type == 'radio' and control.value == 'true'
      $(control).parents(".blue_shift_section").find(".blue_shift_input").show()
      $(control).parents(".blue_shift_section").find(".blue_shift_input_false").hide()
      $(control).parents(".blue_shift_section").resize()

    if control.checked and control.type == 'radio' and control.value == 'false'
      $(control).parents(".blue_shift_section").find(".blue_shift_input").hide()
      $(control).parents(".blue_shift_section").find(".blue_shift_input_false").show()
      $(control).parents(".blue_shift_section").resize()

    if control.name == 'blue_shift[need_help]' and control.type == 'checkbox' and control.checked
      $(control).parent(".blue_shift_section").find(".blue_shift_input").show()
      $(control).parent(".blue_shift_section").find(".blue_shift_input_false").hide()
      $(control).parent(".blue_shift_section").resize()
      $("input[type=radio], input[type=checkbox]").each (index, element) =>
        @setBlueShiftSubSectionVisiblity(element)

    if control.name == 'blue_shift[need_help]' and control.type == 'checkbox' and !control.checked
      $(control).parent(".blue_shift_section").find(".blue_shift_input").hide()
      $(control).parent(".blue_shift_section").find(".blue_shift_input_false").show()
      $(control).parent(".blue_shift_section").resize()


  setBlueShiftSubSectionVisiblity: (control) ->
    if control.name == 'blue_shift[need_help_marketing_problem]' and control.type == 'checkbox' and control.checked
      $(control).parent(".blue_shift_section").find(".blue_shift_input").show()
      $(control).parent(".blue_shift_section").find(".blue_shift_input_false").hide()
      $(control).parent(".blue_shift_section").resize()

    if control.name == 'blue_shift[need_help_marketing_problem]' and control.type == 'checkbox' and !control.checked
      $(control).parent(".blue_shift_section").find(".blue_shift_input").hide()
      $(control).parent(".blue_shift_section").find(".blue_shift_input_false").show()
      $(control).parent(".blue_shift_section").resize()

    if control.name == 'blue_shift[need_help_capital_problem]' and control.type == 'checkbox' and control.checked
      $(control).parent(".blue_shift_section").find(".blue_shift_input").show()
      $(control).parent(".blue_shift_section").find(".blue_shift_input_false").hide()
      $(control).parent(".blue_shift_section").resize()

    if control.name == 'blue_shift[need_help_capital_problem]' and control.type == 'checkbox' and !control.checked
      $(control).parent(".blue_shift_section").find(".blue_shift_input").hide()
      $(control).parent(".blue_shift_section").find(".blue_shift_input_false").show()
      $(control).parent(".blue_shift_section").resize()

  setProductProblemAlert: (control) ->
    if (control.checked and control.type == 'radio' and control.value == 'false' and control.name == 'blue_shift[product_problem]')
      inspection_score = $("#inspection_score").val()
      if (inspection_score)
        inspection_score = inspection_score.replace("%", "")
        if (inspection_score < 90)
          alert("YOUR RECENT INSPECTION SCORE IS #{inspection_score}% - WHICH MEANS YES, YOU HAVE A PRODUCT PROBLEM ")
    
  setupMetricDrillDowns: () ->
    $(document).off 'click', 'span[data-rent-change-reasons]'
    $(document).on 'click', 'span[data-rent-change-reasons]', (e) =>
      $target = $(e.target)
      metricId = $target.parents("span").find(".metric_id").val()
      window.open "/rent_change_reasons?metric_id=#{metricId}", "_self"

  createRCRDataTable: () ->
    options = 
      ajax: 
        url: @baseRCRDataTableUrl
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
      fixedColumns: true
      columnDefs: [
        { targets: [0,1,2,3,4,5,6,7,8,9], visible: true }
      ]
      initComplete: () =>
      drawCallback: () =>
      fnServerParams: (aoData) =>
  
    @RCRDataTable = $("#rent_change_reasons_table").DataTable(options)    
    
    $(window).resize () =>
      height = @getAvailableContentHeight()
      $(".dataTables_scrollBody").css("max-height", "#{height}px")
    
  createCFADataTable: () ->
    options = 
      ajax: 
        url: @baseCFADataTableUrl
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
      fixedColumns: true
      columnDefs: [
        { targets: [0,1,2,3,4,5,6,7,8,9], visible: true }
      ]
      initComplete: () =>
      drawCallback: () =>
      fnServerParams: (aoData) =>
  
    $("#conversions_for_agents_table").DataTable(options)
    
    $(window).resize () =>
      height = @getAvailableContentHeight()
      $(".dataTables_scrollBody").css("max-height", "#{height}px")

  createConversionsForPropertiesDataTable: () ->
    options = 
      ajax: 
        url: @baseConversionsForPropertyDataTableUrl
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
      fixedColumns: true
      columnDefs: [
        { targets: [0,1,2,3,4,5,6,7,8,9,10,11,12,13], visible: true }
      ]
      initComplete: () =>
      drawCallback: () =>
      fnServerParams: (aoData) =>
  
    $("#conversions_for_properties_table").DataTable(options)
    
    $(window).resize () =>
      height = @getAvailableContentHeight()
      $(".dataTables_scrollBody").css("max-height", "#{height}px")

  createAgentSalesRollupDataTable: () ->
    options = 
      ajax: 
        url: @baseAgentSalesRollupDataTableUrl
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
      fixedColumns: true
      columnDefs: [
        { targets: [0,1,2,3,4,5,6,7,8,9,11,12,13,14], visible: true }
      ]
      initComplete: () =>
      drawCallback: () =>
      fnServerParams: (aoData) =>
  
    $("#bluebot_agent_sales_rollup_report_table").DataTable(options)
    
    $(window).resize () =>
      height = @getAvailableContentHeight()
      $(".dataTables_scrollBody").css("max-height", "#{height}px")

  
  getAvailableContentHeight: () ->
    tableHeaderHeight = 57
    heightAdjustment = 18
    
    height = $(window).outerHeight() - $("#header").height() - tableHeaderHeight - heightAdjustment
    return height

  setupUnitTypeRentHistory: () ->
    $(document).off 'click', '#rent_change_reasons tbody td span[data-unit-type-rent-history]'
    $(document).on 'click', '#rent_change_reasons tbody td span[data-unit-type-rent-history]', (e) =>
      $target = $(e.target)
      rentChangeReasonId = $target.parents("tr").find(".rent_change_reason_id").val()
      window.open "/unit_type_rent_history?rent_change_reason_id=#{rentChangeReasonId}", "_self"

  # setupLevel4Cells: () ->
  #   # Fill in background of level-4 cells
  #   $(".level-4").each () ->
  #     $(this).parents("td").addClass("level-4")
