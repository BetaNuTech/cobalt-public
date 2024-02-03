class Cobalt.UsersController
  initialize: () ->
    $("select#user_property_ids").multiSelect()
    @setupActiveConfirmation()
    @enableDisableTeamSelection()
    
  setupActiveConfirmation: () ->
    @originalActive = $('form #user_active').is(':checked')
    @askForDeactivationConfirmation = false
    
    $('form #user_active').change (e) =>
      $checkbox = $(e.target)
      if @originalActive == true and !$checkbox.is(':checked')
        @askForDeactivationConfirmation = true
      else
        @askForDeactivationConfirmation = false
        
    $("form.edit_user").submit (e) =>
      if @askForDeactivationConfirmation and !confirm("Are you sure you wish to deactivate this user?")
        e.preventDefault()
        return false
      
      return true
  

  enableDisableTeamSelection: () ->
    $(document).ready ->
      selection = $('form #user_t2_role').children("option:selected").val()
      if selection == "team_lead_property_manager" || selection == "team_lead_maint_super"
        $('form #user_team_id').removeAttr('disabled');
      else
        $('form #user_team_id').attr('disabled','disabled')

    $('form #user_t2_role').change (e) =>
      selection = $(e.target).children("option:selected").val()
      if selection == "team_lead_property_manager" || selection == "team_lead_maint_super"
        $('form #user_team_id').removeAttr('disabled');
      else
        $('form #user_team_id').attr('disabled','disabled')
    
    # if $('form #user_active').length > 1 and $('form #user_active')
