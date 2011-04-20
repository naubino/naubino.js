class Game
  constructor: (@canvas, @bindings) ->
    @width = @canvas.width
    @height = @canvas.height
    field = [0, 0, @width, @height]
    @time_factor = 1
    @world = new World field
    @create_some_naubs 5

  create_some_naubs: (n) ->
    for [0..n]
      naub = new Naub @world
      x = Math.random() * 600
      y = Math.random() * 400
      naub.physics.pos.Set x, y
      naub.physics.vel.Set 0, 0

  step: (dt) ->
    @world.step dt
  
  draw: (ctx) ->
    ctx.save()
    @world.draw ctx
    ctx.restore()

