define -> class PhysicsModel
  constructor: (@naub) ->
    @pos = new b2Vec2(0, 0)
    @vel = new b2Vec2(0, 0)
    @force = new b2Vec2(0, 0) # acceleration TODO Rename force -> acceleration
    @attracted_to = new b2Vec2 0, 0 # gravity center

    @mass = @default_mass = Naubino.settings.naub.mass
    @friction = @default_friction = Naubino.settings.physics.friction
    @spring_force = Naubino.settings.physics.spring_force
    @margin = Naubino.settings.physics.margin
    @join_length = Naubino.settings.physics.join_length

 
  step: (dt) ->
    v = @force.Copy()
    v.Multiply(dt)
    @pos.Add(v)
    @acceleration = new b2Vec2(0, 0)
    @apply_friction()

  gravitate: (to = @attracted_to) ->
    unless @naub.focused or not @naub.layer.gravity
      diff = to.Copy()
      diff.Subtract(@pos)
      diff.Multiply(@mass/100)
      @accelerate(diff)

  accelerate: (diff) ->
    @force.Add(diff)

  apply_friction: ->
    @force.Multiply(0.4)

  follow: (v = @attracted_to) -> # except when you are held by the pointer
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
      keep_distance = (@naub.size + other.size) * @margin

      diff = opos.Copy()
      diff.Subtract(@pos)
      l = diff.Length()

      if @naub.number < other.number &&  l < keep_distance
        v = diff.Copy()
        v.Normalize()
        v.Multiply(keep_distance - l)
        v.Multiply(0.6)
        @pos.Subtract(v)
        opos.Add(v)
        @force.Subtract(v)
        oforce.Add(v)

  # spring force between joined naubs
  join_springs: (other) ->
    # XXX causes slight rotation when crossing to pairs
    { pos: opos, vel: ovel, force: oforce } = other.physics
    keep_distance = (@naub.size + other.size) * @join_length

    diff = opos.Copy()
    diff.Subtract(@pos)
    l = diff.Length()
    v = diff.Copy()

    v.Normalize()
    v.Multiply( -1/1000 * @spring_force * l * l * l % 1000)
    @force.Subtract(v)
    oforce.Add(v)

    if (l < keep_distance)
      v = diff.Copy()
      v.Normalize()
      v.Multiply(keep_distance - l)
      v.Multiply(0.3)
      @vel.Subtract(v)
      ovel.Add(v)
      @force.Subtract(v)
      oforce.Add(v)

