@Naubino.PhysicsModel = class PhysicsModel
  constructor: (@naub) ->
    @pos = new b2Vec2(0, 0)
    @vel = new b2Vec2(0, 0)
    @force = new b2Vec2(0, 0) # acceleration TODO Rename force -> acceleration
    @radius = @naub.size
    @attracted_to = new b2Vec2 0, 0 # gravity center

    @mass = 0.3
    @friction = @default_friction = 4.0
    @spring_force = 0.03
    @keep_distance = @radius*2 + 10
 
  step: (dt) ->
    v = @force.Copy()
    v.Multiply(dt)
    @pos.Add(v)
    @acceleration = new b2Vec2(0, 0)
    @apply_friction()

  gravitate: (to = @attracted_to) ->
    unless  @naub.focused
      diff = to.Copy()
      diff.Subtract(@pos)
      diff.Multiply(@mass)
      @accelerate(diff)

  accelerate: (diff) ->
    @force.Add(diff)

  apply_friction: ->
    @force.Multiply(0.4)

  follow: (v = @naub.center) -> # except when you are held by the pointer
      pl = v.Copy()
      pl.Subtract(@pos)
      pl = pl.Length()

      v.Subtract(@pos)
      v.Normalize()
      v.Multiply(30*pl)
      @force.Add(v)

  # keep naubs from overlapping
  collide: (other) ->
    if (@naub.number != other.number)
      { pos: opos, vel: ovel, force: oforce } = other.physics

      diff = opos.Copy()
      diff.Subtract(@pos)
      l = diff.Length()

      if @naub.number < other.number &&  l < 35  # TODO replace with obj size
        v = diff.Copy()
        v.Normalize()
        v.Multiply(35 - l)
        v.Multiply(0.6)
        @pos.Subtract(v)
        opos.Add(v)
        @force.Subtract(v)
        oforce.Add(v)

  # spring force between joined naubs
  join_springs: (other) ->
    # XXX causes slight rotation when crossing to pairs
    { pos: opos, vel: ovel, force: oforce } = other.physics

    diff = opos.Copy()
    diff.Subtract(@pos)
    l = diff.Length()
    v = diff.Copy()

    v.Normalize()
    v.Multiply( -1/100 * @spring_force * l * l * l)
    @force.Subtract(v)
    oforce.Add(v)

    if (l < @naub.keep_distance) # TODO replace with obj size
      v = diff.Copy()
      v.Normalize()
      v.Multiply(@naub.keep_distance - l)
      v.Multiply(0.3)
      @vel.Subtract(v)
      ovel.Add(v)
      @force.Subtract(v)
      oforce.Add(v)

