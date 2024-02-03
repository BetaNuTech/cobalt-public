class Cobalt.MaintBlueShift
     
  @update: (id, property_id, update_options, callback) ->
    $.ajax
      url: "/properties/#{property_id}/maint_blue_shifts/#{id}.json",
      type: 'PATCH'
      data:
        maint_blue_shift:
          update_options
      success: () ->
        callback() if callback?  
      error: () ->
        alert "Update failed."
    
