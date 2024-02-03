class Cobalt.MaintBlueShiftsNewController
  
  initialize: () ->
    if $("#part_image_uploads .uploaded_image").length > 0
      @partImageUploadIndex = $(".uploaded_image").length - 1
    else
      @partImageUploadIndex = -1
      
    $("input[type=radio], input[type=checkbox]").each (index, element) =>
      @setBlueShiftSectionVisiblity(element)
      
    $("input[type=radio], input[type=checkbox]").change (event) =>
      target = event.target
      @setBlueShiftSectionVisiblity(target)
      
    $(".date").datepicker(minDate: 0)
    
    if $('#image_upload_template').length > 0
      @addImageUploadField("Upload an image")

    current_metric_id = $('#current_metric_id').val()
    property_id = $('#property_id').val()
    current_metric_id = $('#current_metric_id').val()
    date =  $("#created_on_date").val()
      
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
        $imageUploadField.after("Caption <input type='text' class='image_caption' maxlength='255' id='blue_shift_parts_problem_image_caption_#{@partImageUploadIndex}' name='blue_shift[parts_problem_image_caption_#{@partImageUploadIndex}]'>")
        $imageUploadField.after("<img src='#{data.result.url}'><br />")
        
        $("#part_image_uploads .upload_label").remove()
        
        @addImageUploadField("Upload another image")
        
      fail: (e, data) ->
        alert("Error uploading image: #{data.errorThrown} - #{data.failReason}")
      progress: (e, data) ->
        progress = parseInt(data.loaded / data.total * 100, 10)
        $meter.css(width: "#{progress}%")    
   
  addImageUploadField: (label) ->    
    @partImageUploadIndex += 1  
    $imageUpload = $("#image_upload_template .image_upload").clone()
    $imageUpload.find(".upload_label").text(label)
    $("#part_image_uploads").append($imageUpload)
    
    $imageUploadField = $imageUpload.find(".js-s3_file_field")
    $imageUploadField.attr("id", $imageUploadField.attr("id").replace("index", @partImageUploadIndex))
    $imageUploadField.attr("name", $imageUploadField.attr("name").replace("index", @partImageUploadIndex))
    @configureImageUploadField($imageUploadField)
        
  setBlueShiftSectionVisiblity: (control) ->
    if control.checked and ((control.type == 'radio' and control.value == 'true') or (control.type == 'checkbox' and (control.name == 'blue_shift[need_help]' or control.name == 'maint_blue_shift[need_help]')))
      $(control).parents(".blue_shift_section").find(".blue_shift_input").show()
      $(control).parents(".blue_shift_section").find(".blue_shift_input_false").hide()
      $(control).parents(".blue_shift_section").resize()

    if (control.checked and control.type == 'radio' and control.value == 'false') or (!control.checked and control.type == 'checkbox' and (control.name == 'blue_shift[need_help]' or control.name == 'maint_blue_shift[need_help]'))
      $(control).parents(".blue_shift_section").find(".blue_shift_input").hide()
      $(control).parents(".blue_shift_section").find(".blue_shift_input_false").show()
      $(control).parents(".blue_shift_section").resize()
  
  getAvailableContentHeight: () ->
    tableHeaderHeight = 57
    heightAdjustment = 18
    
    height = $(window).outerHeight() - $("#header").height() - tableHeaderHeight - heightAdjustment
    return height
