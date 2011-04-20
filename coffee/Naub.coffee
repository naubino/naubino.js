class Naub
  constructor: (@world) ->
    @physics = new PhysicsModel
    @shape = new NaubShape @physics
    @removed = false
    @world.add_obj this

  draw: (context)  =>
    @shape.draw context
    
  step: (dt) =>
    @physics.step dt
    
  remove: ->
    @removed = true





