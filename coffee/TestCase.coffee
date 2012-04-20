define ["Naub","Game","Shapes"], (Naub,Game,{NumberShape, Ball, FrameCircle}) -> class TestCase extends Game
  #  constructor: ->
  #    super()
  oninit: ->
    #@create_some_naubs 2
    @create_matching_naubs()
    @gravity = on
    Naubino.naub_replaced.add (number)=> @graph.cycle_test(number)
    Naubino.cycle_found.add (list) => @destroy_naubs(list)
    #Naubino.play()

  onplaying: ->
    weightless = => @gravity = off
    #setTimeout(weightless, 4000)
    Naubino.settings.graphics.updating = off

    basket = 150
    @animation.play()
    @basket_size = basket
    Naubino.background.basket_size = basket
    Naubino.background.draw()

  onpaused: ->
    @animation.pause()

  onunset:->
    Naubino.add_signals()
    console.log("standart_game clear")
    Naubino.settings.show_numbers = false
    @clear()
    Naubino.background.clear()


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
