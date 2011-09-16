@Naubino.PhysicsModel = class PhysicsModel
  constructor: (@naub) ->
    @stuck = false # means it won't move at all
    @pos = new b2Vec2(0, 0)
    @vel= new b2Vec2(0, 0)
    @force = new b2Vec2(0, 0)
    @friction = @default_friction = 4.0
    @spring_force = 0.03
    @keep_distance = 40
    @mass = 1
 
  step: (dt) ->
    unless @stuck
      v = @force.Copy()
      v.Multiply(dt)
      @pos.Add(v)
      @pos.Add(@vel) unless @stuck
      @force.Multiply 1/(@friction*@mass)
      @vel.Set 0, 0

  gravitate:(center = @naub.center) ->
    unless  @naub.focused
      # TODO make gravity stronger the close it gets
      if Naubino.Settings.gravity # debug hook
        v = center.Copy()
        v.Subtract(@pos)
        v.Normalize()
        v.Multiply(20*@mass)
        @force.Add(v)

  follow: (v) -> # except when you are held by the pointer
      pl = v.Copy()
      pl.Subtract(@pos)
      pl = pl.Length()

      v.Subtract(@pos)
      v.Normalize()
      v.Multiply(30*pl)
      @force.Add(v)

  stay_in_place: ->
    @naub.center = @pos
