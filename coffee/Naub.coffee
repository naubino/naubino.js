class Naub
  constructor: (@world) ->
    @physics = new PhysicsModel
    @shape = new NaubShape this
    @removed = false
    @world.add_obj this

  draw: (context)  =>
    @shape.draw context
    
  step: (dt) =>
    @physics.step dt
    
  remove: =>
    @removed = true

  isHit: (x, y) ->
    ox = @physics.pos.x
    oy = @physics.pos.y
    distance = Math.sqrt((x - ox) + (y - oy)*(y - oy))
    distance < @shape.size

