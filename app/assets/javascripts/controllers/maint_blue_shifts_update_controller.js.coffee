class Cobalt.MaintBlueShiftsUpdateController
  initialize: () ->
    Cobalt.maintBlueShiftsShowController = new Cobalt.MaintBlueShiftsShowController()
    Cobalt.maintBlueShiftsShowController.initialize()
