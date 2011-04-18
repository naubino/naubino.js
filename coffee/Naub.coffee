window.Naub = class Naub
  constructor: ->
    @physics = new PhysicsModel
    @shape = new NaubShape

  draw: (context)  =>
    @shape.draw(context)





