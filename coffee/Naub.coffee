class Naub
  constructor: (@world) ->
    @physics = new PhysicsModel
    @shape = new NaubShape this
    @removed = false
    @world.add_obj this
    @joins = []

  draw: (context)  =>
    @shape.draw context
    
  step: (dt) =>
    @physics.step dt
    
  remove: =>
    @removed = true

  joinWith: (other_naub) ->
    # Check if already joined
    # check for cycle
    join = new Join(this, naub)
    @joins.push join
    naub.joins.push join


  isHit: (x, y) ->
    ox = @physics.pos.x
    oy = @physics.pos.y
    distance = Math.sqrt((x - ox) + (y - oy)*(y - oy))
    distance < @shape.size

