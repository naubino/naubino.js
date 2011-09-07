class PhysicsModel
  constructor: ->
    @pos = new b2Vec2(0, 0)
    @force = new b2Vec2(0, 0)
    @friction = @default_friction = 2.0
    @spring_force = 0.01

  step: (dt) ->
    v = @force.Copy()

    v.Multiply(dt)
    @pos.Add(v)
    @force.Multiply 1/@friction
