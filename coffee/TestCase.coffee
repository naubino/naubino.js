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
    Naubino.background.animation.play()
    Naubino.background.start_stepper()

    weightless = => @gravity = off
    #setTimeout(weightless, 4000)

  event:->
    inner_basket = @count_basket()
    @destroy_naubs inner_basket

  create_naub_pair: (x=null, y=x, color_a = null, color_b = null) ->

    {x,y} = @random_outside() unless x?

    naub_a = new Naub this, color_a
    naub_b = new Naub this, color_b
    color_a = naub_a.color_id
    color_b = naub_b.color_id

    naub_a.add_shape new Ball
    naub_a.add_shape new FrameCircle
    naub_b.add_shape new Ball
    naub_b.add_shape new FrameCircle


    color_a = naub_a.color_id
    color_b = naub_b.color_id

    @add_object naub_a
    @add_object naub_b

    naub_a.add_shape new NumberShape
    naub_b.add_shape new NumberShape

    naub_a.update() # again just to get the numbers
    naub_b.update() # again just to get the numbers

    dir = Math.random() * Math.PI

    naub_a.physics.pos.Set x, y
    naub_b.physics.pos.Set x, y

    naub_a.physics.pos.AddPolar(dir, 15)
    naub_b.physics.pos.AddPolar(dir, -15)

    naub_a.join_with naub_b
    [color_a, color_b]
