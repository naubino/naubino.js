Naubino.Tutorial = class Tutorial extends Naubino.RuleSet
  @name = "Tutorial"
  constructor: ->
    super()


  configure: ->
    super()

    console.log @events.length

    Naubino.menu_focus.addOnce =>
      console.log "dont look at the menu just now"
      Naubino.menu_focus.active = false


  run: ->


  halt:->


  events: [
    =>
      Naubino.overlay.fade_in_message("you just clicked")
    ]
  event: ->


