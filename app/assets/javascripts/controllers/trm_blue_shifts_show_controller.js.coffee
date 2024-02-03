class Cobalt.TrmBlueShiftsShowController
  initialize: () ->
    Cobalt.trmBlueShiftsNewController = new Cobalt.TrmBlueShiftsNewController()
    Cobalt.trmBlueShiftsNewController.initialize()
    
    @setupArchiving()
    @setupEditArchive()
    
    $("#trm_blue_shift_form input:not(.editable,[type=hidden]), #trm_blue_shift_form textarea:not(.editable), #trm_blue_shift_form select:not(.editable), #trm_blue_shift_form check_box:not(.editable)").attr('disabled', 'disabled');
    
    $(".change_date input.editable").datepicker
      minDate: 0
      onSelect: (e, ui) ->
        trmBlueShiftId = $("#trm_blue_shift_id").val()
        propertyId = $("#property_id").val()
        attribute = ui.input.data("attribute")
        # Not used, but could be used to update form?
        
    
    $(document).off "click", "#trm_blue_shift_form .comment_form_actions input.update[name=commit]"      
    $(document).on "click", "#trm_blue_shift_form .comment_form_actions input.update[name=commit]", (e) =>
      commentId = $(e.target).parents(".comment").first().attr("data-id")
      @postToComments(e.target, commentId, false)
      e.preventDefault()
    
    $(document).off "click", "#trm_blue_shift_form .comment_form_actions input.create[name=commit]"      
    $(document).on "click", "#trm_blue_shift_form .comment_form_actions input.create[name=commit]", (e) =>
      @postToComments(e.target, null, false)
      e.preventDefault()
    
    $(document).off "click", "#trm_blue_shift_form .comment_form_actions input[name=cancel]"  
    $(document).on "click", "#trm_blue_shift_form .comment_form_actions input[name=cancel]", (e) =>
      @postToComments(e.target, null, true)
      e.preventDefault()

  setupArchiving: () ->
    $('#archive_action').click (e) =>
      e.preventDefault()
      $('#archive_action').hide()
      $('#archive_details_container').show()
      return false
      
    $('#cancel_archiving').click (e) =>
      e.preventDefault()
      $('#archive_action').show()
      $('#archive_details_container').hide()
      return false
      
      
    $('#archive_container form#edit_trm_blue_shift').submit (e) =>
      if $("#archive_details_container input[type=radio]:checked").length == 0
        e.preventDefault()
        alert("You must select an option for whether the TRM BlueShift was a success or failure.")
        return false

  setupEditArchive: () ->
    $('#edit_archive_action').click (e) =>
      e.preventDefault()
      $('#edit_archive_action').hide()
      $('#edit_archive_details_container').show()
      return false
      
    $('#cancel_edit_archive').click (e) =>
      e.preventDefault()
      $('#edit_archive_action').show()
      $('#edit_archive_details_container').hide()
      return false
      
    $('#edit_archive_details_container form#edit_blue_shift').submit (e) =>
      if $("#edit_archive_details_container input[type=radio]:checked").length == 0
        e.preventDefault()
        alert("You must select an option for whether the TRM BlueShift was a success or failure.")
        return false
      
  postToComments: (target, commentId, cancel) ->
    $target = $(target)
    body = $target.parents(".thread").find("#comment_body").val()
    data = comment:
      body: body
      
    if cancel
      data['cancel'] = "Cancel"
      
    if commentId == null
      threadId = $target.parents(".thread").first().prev(".comment_thread_id").val()
      url ="/comments/threads/#{threadId}/comments.js"
    else
      url = "/comments/comments/#{commentId}.js"
    
    $.ajax
      method: if commentId == null then 'post' else 'put'
      url: url
      dataType: "script"
      data: data
    
    return false  
