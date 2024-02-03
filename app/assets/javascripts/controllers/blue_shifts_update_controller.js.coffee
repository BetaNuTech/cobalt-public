class Cobalt.BlueShiftsUpdateController
  initialize: () ->
    Cobalt.blueShiftsShowController = new Cobalt.BlueShiftsShowController()
    Cobalt.blueShiftsShowController.initialize()
