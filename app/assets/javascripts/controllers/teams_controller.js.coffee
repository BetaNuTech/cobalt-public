class Cobalt.TeamsController
  initialize: () ->
    @setupActiveConfirmation()
    
  setupActiveConfirmation: () ->
    @originalActive = $('form #team_active').is(':checked')
    @askForDeactivationConfirmation = false
    
    $('form #team_active').change (e) =>
      $checkbox = $(e.target)
      if @originalActive == true and !$checkbox.is(':checked')
        @askForDeactivationConfirmation = true
      else
        @askForDeactivationConfirmation = false
        
    $("form.edit_team").submit (e) =>
      if @askForDeactivationConfirmation and !confirm("Are you sure you wish to deactivate this team?")
        e.preventDefault()
        return false
      
      return true
    
    
    # if $('form #user_active').length > 1 and $('form #user_active')
