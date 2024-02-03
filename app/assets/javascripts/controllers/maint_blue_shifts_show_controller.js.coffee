class Cobalt.MaintBlueShiftsShowController
  initialize: () ->
    Cobalt.maintBlueShiftsNewController = new Cobalt.MaintBlueShiftsNewController()
    Cobalt.maintBlueShiftsNewController.initialize()
    
    @setupArchiving()
    @setupEditArchive()
    
    $("#blue_shift_form input:not(.editable,[type=hidden]), #blue_shift_form textarea:not(.editable)").attr('disabled', 'disabled');
    
    $(".change_date input.editable").datepicker
      minDate: 0
      onSelect: (e, ui) ->
        blueShiftId = $("#blue_shift_id").val()
        propertyId = $("#property_id").val()
        attribute = ui.input.data("attribute")
        
        # Cobalt.MaintBlueShift.update blueShiftId, propertyId, { "#{attribute}": e}, () ->
        #   ui.input.parents(".blue_shift_input").find('.readonly_date').text(e)
          
    
    $(document).off "click", "#blue_shift_form .comment_form_actions input.update[name=commit]"      
    $(document).on "click", "#blue_shift_form .comment_form_actions input.update[name=commit]", (e) =>
      commentId = $(e.target).parents(".comment").first().attr("data-id")
      @postToComments(e.target, commentId, false)
      e.preventDefault()
    
    $(document).off "click", "#blue_shift_form .comment_form_actions input.create[name=commit]"      
    $(document).on "click", "#blue_shift_form .comment_form_actions input.create[name=commit]", (e) =>
      @postToComments(e.target, null, false)
      e.preventDefault()
    
    $(document).off "click", "#blue_shift_form .comment_form_actions input[name=cancel]"  
    $(document).on "click", "#blue_shift_form .comment_form_actions input[name=cancel]", (e) =>
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
      
    $('#archive_container form#edit_blue_shift').submit (e) =>
      if $("#archive_details_container input[type=radio]:checked").length == 0
        e.preventDefault()
        alert("You much select an option for whether the BlueShift was a success or failure.")
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
        alert("You much select an option for whether the BlueShift was a success or failure.")
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
