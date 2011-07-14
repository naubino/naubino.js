class Game
  constructor: (@canvas, @keybindings) ->
    # TODO Exchangeable display class
    @width = @canvas.width
    @height = @canvas.height
    field = [0, 0, @width, @height]
    @time_factor = 1
    @world = new World field
    @ctx = @canvas.getContext('2d')

  create_some_naubs: (n) ->
    for [0..n]
      naub = new Naub @world
      naub.shape.style.fill = naub.shape.random_color()
      x = Math.random() * 600
      y = Math.random() * 400
      naub.physics.pos.Set x, y
      naub.physics.vel.Set 0, 0

  step: (dt) ->
    @world.step dt
  
  draw: (ctx) ->
    ctx.clearRect(0, 0, @canvas.width, @canvas.height)
    ctx.save()
    @world.draw ctx
    ctx.restore()

  mainloop: ()=>
    dt = 0.02
    @step(dt)
    @keybindings.step(dt)
    @draw(@ctx)
