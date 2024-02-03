class Cobalt.TrmBlueShiftsNewController
  
  initialize: () ->
    $("input[type=radio], input[type=checkbox]").each (index, element) =>
      @setTrmBlueShiftSectionVisiblity(element)
      
    $("input[type=radio], input[type=checkbox]").change (event) =>
      target = event.target
      @setTrmBlueShiftSectionVisiblity(target)
      
    $(".date").datepicker(minDate: 0)
    
    current_metric_id = $('#current_metric_id').val()
    property_id = $('#property_id').val()
    date =  $("#created_on_date").val() 
      
    return  
        
  setTrmBlueShiftSectionVisiblity: (control) ->
    if control.checked and control.type == 'radio' and control.value == 'true'
      $(control).parents(".trm_blue_shift_section").find(".trm_blue_shift_input").show()
      $(control).parents(".trm_blue_shift_section").find(".trm_blue_shift_input_false").hide()
      $(control).parents(".trm_blue_shift_section").resize()

    if control.checked and control.type == 'radio' and control.value == 'false'
      $(control).parents(".trm_blue_shift_section").find(".trm_blue_shift_input").hide()
      $(control).parents(".trm_blue_shift_section").find(".trm_blue_shift_input_false").show()
      $(control).parents(".trm_blue_shift_section").resize()

