define ["Naub","Game","Shapes","StandardGame"], (Naub,Game,{StringShape, NumberShape, Ball, FrameCircle}, StandardGame) -> class TestCase extends Game 
  #  constructor: ->
  #    super()
  oninit: ->
    super()
    Naubino.settings.graphics.updating = off
    Naubino.settings.game.creation_offset = -200
    #@factory.add_ball = @add_ball

    @naub_replaced.add (number)=> @graph.cycle_test(number)
    @cycle_found.add (list) => @destroy_naubs(list)
    setTimeout (-> Naubino.play()), 300

  onplaying: (e,f,t)->
    @factory.create_matching_naubs() if f == "stopped"
    
    for [..5]
      @add_ball()
    #Naubino.background.animation.play()
    #Naubino.background.start_stepper()

    weightless = => @gravity = off
    #setTimeout(weightless, 4000)



  event:->
  #check: =>

  add_ball: (pos = @factory.random_outside(), color = null) =>
    naub = new Naub this, color
    ball = new Ball

    naub.add_shape ball
    naub.setup_physics()
    naub.physical_body.setPos( pos.Copy() ) # remember to set position
    naub.kind = 'ball'

    @add_object naub
    #naub.add_shape new StringShape (-> naub.physical_body.m), 'white'
    naub.add_shape new StringShape naub.number, 'white'
    naub.update() # again just to get the numbers
    naub
