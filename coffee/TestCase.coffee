define ["Naub","Game","Shapes","StandardGame"], (Naub,Game,{NumberShape, Ball, FrameCircle}, StandardGame) -> class TestCase extends StandardGame
  #  constructor: ->
  #    super()
  oninit: ->
    #@create_some_naubs 2
    @create_matching_naubs()
    @gravity = on
    @naub_replaced.add (number)=> @graph.cycle_test(number)
    @cycle_found.add (list) => @destroy_naubs(list)
    Naubino.play()

  onplaying: ->
    @animation.play()
    @start_stepper()
    #Naubino.background.animation.play()
    #Naubino.background.start_stepper()

    weightless = => @gravity = off
    #setTimeout(weightless, 4000)

  event:->
    inner_basket = @count_basket()
    @destroy_naubs inner_basket

