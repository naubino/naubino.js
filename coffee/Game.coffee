class Game
  constructor: (@canvas, @bindings) ->
    @width = @canvas.width
    @height = @canvas.height
    field = [0, 0, @width, @height]
    @time_factor = 1
    @world = new World field
    @create_some_naubs 1

  create_some_naubs: (n) ->
    for [0..n]
      naub = new Naub @world
      naub.physics.pos.Set 50, 50
      naub.physics.vel.Set 50, 0

  step: (dt) ->
    @world.step dt
  
  draw: (ctx) ->
    ctx.save()
    @world.draw ctx
    ctx.restore()

