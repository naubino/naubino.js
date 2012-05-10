define ["Naub","Game","Shapes","StandardGame"], (Naub,Game,{NumberShape, Ball, FrameCircle}, StandardGame) -> class TestCase extends StandardGame
  #  constructor: ->
  #    super()
  oninit: ->
    super()
    Naubino.settings.graphics.updating = on
    Naubino.settings.game.creation_offset = -50
    @factory.create_matching_naubs()

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

  add_ball: (pos = @random_outside(), color = null) =>
    naub = new Naub this, color
    ball = new Ball

    naub.add_shape ball
    naub.setup_physics()
    naub.physical_body.setPos( pos.Copy() ) # remember to set position
    naub.kind = 'ball'

    @add_object naub
    naub.add_shape new NumberShape
    #naub.update() # again just to get the numbers
    naub
