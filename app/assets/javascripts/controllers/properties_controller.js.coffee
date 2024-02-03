class Cobalt.PropertiesController
  initialize: () ->
    $("select#team_id").multiSelect()
    @setupActiveConfirmation()
    
  setupActiveConfirmation: () ->
    @originalActive = $('form #property_active').is(':checked')
    @askForDeactivationConfirmation = false
    
    $('form #property_active').change (e) =>
      $checkbox = $(e.target)
      if @originalActive == true and !$checkbox.is(':checked')
        @askForDeactivationConfirmation = true
      else
        @askForDeactivationConfirmation = false
        
    $("form.edit_property").submit (e) =>
      if @askForDeactivationConfirmation and !confirm("Are you sure you wish to deactivate this property?")
        e.preventDefault()
        return false
      
      return true
    
    
    # if $('form #user_active').length > 1 and $('form #user_active')
