class Cobalt.BlueShift
     
  @update: (id, property_id, update_options, callback) ->
    $.ajax
      url: "/properties/#{property_id}/blue_shifts/#{id}.json",
      type: 'PATCH'
      data:
        blue_shift:
          update_options
      success: () ->
        callback() if callback?  
      error: () ->
        alert "Update failed."
    
