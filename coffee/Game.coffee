class Game
  constructor: (@canvas, @keybindings) ->
    # TODO Exchangeable display class
    @width = @canvas.width
    @height = @canvas.height
    field = [0, 0, @width, @height]
    @time_factor = 1
    @world = new World field
    @graph = new Graph
    @context = @canvas.getContext('2d')

  create_some_naubs: (n) ->
    for [0..n]
      naub_a = new Naub @world
      naub_b = new Naub @world
      naub_a.shape.style.fill = naub_a.shape.random_color()
      naub_b.shape.style.fill = naub_b.shape.random_color()
      x = Math.random() * 600
      y = Math.random() * 400
      naub_a.physics.pos.Set x, y
      naub_b.physics.pos.Set x + 50, y + 50
      naub_a.physics.vel.Set 0, 0
      naub_b.physics.vel.Set 0, 0
      naub_a.joinWith naub_b

  step: (dt) ->
    @world.step dt

  click: (x, y) ->
    @getNaub x, y

  getNaub: (x, y) ->
    for naub in @world.objs
      if naub.isHit(x, y)
        console.log naub.number + " -> " + naub.joins[0].number

  draw: (context) ->
    context.clearRect(0, 0, @canvas.width, @canvas.height)
    context.save()
    @world.draw context
    context.restore()

  mainloop: ()=>
    dt = 0.02
    @step(dt)
    @keybindings.step(dt)
    @draw(@context)
