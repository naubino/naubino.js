Naubino.Tutorial = class Tutorial extends Naubino.RuleSet
  @name = "Tutorial"
  constructor: ->
    super()
    Naubino.overlay.fade_in_message("Welcome to Naubino", 25)


  configure: ->
    super()
    Naubino.menu_focus.active = false

    @event_i = 0

    Naubino.mousedown.add( =>
      console.log "run #{@event_i}"
      @run()
    )

  run: ->
    @events.length
    console.log @events[@event_i].call()
    @event_i++


  halt:->


  events: [
      ->
        Naubino.overlay.fade_out()
        Naubino.game.create_matching_naubs(2)
        Naubino.game.start_timer()
        weightless = -> Naubino.game.gravity = off
        setTimeout(weightless, 4000)
      -> console.log "step two"
      -> console.log "step three"
      -> console.log "and so on"
      -> Naubino.mousedown.active = false
    ]
  event: ->


