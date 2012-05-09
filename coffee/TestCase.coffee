define ["Naub","Game","Shapes","StandardGame"], (Naub,Game,{NumberShape, Ball, FrameCircle}, StandardGame) -> class TestCase extends StandardGame
  #  constructor: ->
  #    super()
  oninit: ->
    super()
    @create_matching_naubs()
    Naubino.settings.graphics.updating = on
    Naubino.settings.game.creation_offset = -50

    @gravity = on
    @naub_replaced.add (number)=> @graph.cycle_test(number)
    @cycle_found.add (list) => @destroy_naubs(list)
    Naubino.play()

  onplaying: ->
    super()
    #Naubino.background.animation.play()
    #Naubino.background.start_stepper()

    weightless = => @gravity = off
    #setTimeout(weightless, 4000)

  event:->
  #check: =>

