class PhysicsModel
  constructor: ->
    @pos = new b2Vec2(0, 0)
    @vel = new b2Vec2(0, 0)
    @force = new b2Vec2(0, 0)
    
  step: (dt) ->
    v = @force.Copy()
    v.Multiply(dt)
    v.Add(@vel)
    v.Multiply(dt)
    @pos.Add(v)
    @force.Set(0, 0)
