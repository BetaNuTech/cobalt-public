$(document).on 'ready page:load', () ->
  controllerName = $('#javascript_controller_identifier').val()
  return if typeof controllerName == 'undefined'

  controllerInstanceName = controllerName.charAt(0).toLowerCase() + controllerName.slice(1)
  
  if typeof Cobalt[controllerName] != 'undefined'
    unless Cobalt[controllerInstanceName]?
      Cobalt[controllerInstanceName] = new Cobalt[controllerName]()
    Cobalt[controllerInstanceName].initialize() if typeof Cobalt[controllerInstanceName].initialize != 'undefined'
