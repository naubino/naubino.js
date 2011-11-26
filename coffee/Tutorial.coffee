Naubino.Tutorial = class Tutorial extends Naubino.RuleSet
  @name = "Tutorial"
  constructor: ->
    super()


  configure: ->
    super()
    #Naubino.overlay.hide()
    #Naubino.menu.hide()
    #Naubino.game.hide()
    #Naubino.background.hide()
    #Naubino.background.draw()
    Naubino.state_machine.mousedown.add =>
      console.log "hello"
      Naubino.overlay.fade_in_message("you just clicked")


  run: ->


  halt:->


  events: [
    ->
      Naubino.overlay.draw_text("hello world",25)
      Naubino.overlay.fade_in()
      setTimeout()
    ->
      Naubino.overlay
    ]
  event: ->


